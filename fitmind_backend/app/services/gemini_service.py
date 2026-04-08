import google.genai as genai
from app.core.config import settings
import json
import logging
import time
import random

logger = logging.getLogger(__name__)

# Initialize the client
client = genai.Client(api_key=settings.gemini_api_key)

def get_model_response(model_id, contents):
    """
    Generate content with exponential backoff retry logic for 503/429 errors.
    """
    max_retries = 3
    base_delay = 2 # seconds
    
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=model_id,
                contents=contents
            )
            return response
        except Exception as e:
            error_str = str(e)
            if ("503" in error_str or "429" in error_str) and attempt < max_retries - 1:
                delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
                logger.warning(f"AI Service busy ({error_str}). Retrying in {delay:.1f}s (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue
            raise e

async def generate_workout_plan(user_data, preferences):
    """
    Generate a personalized workout plan using Google Gemini AI

    Args:
        user_data (dict): User metrics including age, gender, height, weight, BMI, goal, activity_level
        preferences (dict): Training preferences including gym_access, days_per_week, hours_per_session

    Returns:
        dict: Structured workout plan in JSON format
    """
    try:
        # Generate unique seed for this session to ensure different plans
        unique_seed = f"{int(time.time() * 1000)}_{random.randint(1000, 9999)}"

        # Log the received preferences for debugging
        logger.info(f"Received preferences - gym_access: {preferences.get('gym_access', True)}, days_per_week: {preferences.get('days_per_week', 3)}, hours_per_session: {preferences.get('hours_per_session', 1.0)}, gym_level: {preferences.get('gym_level', 'Beginner')}")

        # Determine BMI category
        bmi = user_data.get('bmi', 22.5)
        if bmi < 18.5:
            bmi_category = "Underweight"
        elif bmi < 25:
            bmi_category = "Normal weight"
        elif bmi < 30:
            bmi_category = "Overweight"
        else:
            bmi_category = "Obese"

        # Build comprehensive prompt with unique seed
        prompt = f"""
You are a professional fitness trainer. Generate a UNIQUE personalized weekly workout plan in JSON format only.

SESSION ID: {unique_seed} - This must generate a COMPLETELY DIFFERENT plan than any previous ones.

User Profile:
- Age: {user_data.get('age', 25)}
- Gender: {user_data.get('gender', 'Male')}
- Height: {user_data.get('height', 170)} cm
- Weight: {user_data.get('weight', 70)} kg
- BMI: {bmi:.1f} ({bmi_category})
- Fitness Goal: {", ".join(user_data.get('goals', [])) if user_data.get('goals') else user_data.get('goal', 'General Fitness')}
- Activity Level: {user_data.get('activity_level', 'Moderately Active')}

Training Preferences:
- Gym Access: {preferences.get('gym_access', True)}
- Days per Week: {preferences.get('days_per_week', 3)}
- Hours per Session: {preferences.get('hours_per_session', 1.0)}

CRITICAL INSTRUCTIONS FOR UNIQUENESS AND PREFERENCES:
1. Session ID {unique_seed} means this plan MUST BE DIFFERENT from all previous plans
2. GYM ACCESS IS {preferences.get('gym_access', True)}:
   - If gym_access is TRUE: Use equipment-based exercises (dumbbells, barbells, machines, cables)
   - If gym_access is FALSE: Use ONLY bodyweight exercises (push-ups, squats, planks, etc.)
3. DAYS PER WEEK IS {preferences.get('days_per_week', 3)}:
   - Create EXACTLY {preferences.get('days_per_week', 3)} workout days
   - Structure the split accordingly (full body, push/pull/legs, upper/lower, etc.)
4. HOURS PER SESSION IS {preferences.get('hours_per_session', 1.0)}:
   - Plan for approximately {preferences.get('hours_per_session', 1.0)} hours per workout
   - Include appropriate number of exercises and sets for this time
5. Choose COMPLETELY DIFFERENT exercises than typical ones
6. Use UNIQUE muscle group combinations based on the preferences
7. Vary the workout structure significantly

EXERCISE SELECTION RULES:
- Gym Access TRUE: Focus on compound lifts (bench press, deadlifts, squats, rows, overhead press)
- Gym Access FALSE: Focus on bodyweight movements (burpees, lunges, dips, pull-ups if possible)
- Always match equipment availability to exercise selection
- Never include gym equipment if gym_access is False

WORKOUT STRUCTURE RULES:
- {preferences.get('days_per_week', 3)} training days = appropriate split (full body, push/pull, upper/lower)
- {preferences.get('hours_per_session', 1.0)} hours = {int(preferences.get('hours_per_session', 1.0) * 60)} minutes per session
- Include 4-6 exercises per session for {preferences.get('hours_per_session', 1.0)} hours

Instructions:
1. Create a realistic workout plan based on user's profile and preferences
2. Consider BMI category - {bmi_category} individuals need appropriate intensity
3. Match exercise selection to gym access (bodyweight vs equipment)
4. Structure for {preferences.get('days_per_week', 3)} days per week
5. Plan for approximately {preferences.get('hours_per_session', 1.0)} hours per session
6. Include proper warm-up and cool-down
7. Provide progressive overload suggestions
8. Return ONLY valid JSON, no additional text

Required JSON Structure:
{{
  "weekly_split": "brief description of the split",
  "days": [
    {{
      "day": "Day Name",
      "focus": "Primary muscle group(s)",
      "duration_minutes": session_duration,
      "exercises": [
        {{
          "name": "Exercise Name",
          "sets": number,
          "reps": "rep_range",
          "rest_seconds": rest_time,
          "notes": "progression tips"
        }}
      ],
      "warmup": "warm-up description",
      "cooldown": "cool-down description"
    }}
  ]
}}

Generate a UNIQUE workout plan for session {unique_seed} now:
"""

        # Generate response using retry logic
        logger.info("Calling Gemini AI (gemini-2.5-flash-lite) for workout plan generation")
        response = get_model_response('gemini-2.5-flash-lite', prompt)

        if not response or not hasattr(response, 'text'):
            logger.error("No response from Gemini AI")
            raise ValueError("No response from AI service")

        # Clean and parse JSON response
        text_response = response.text.strip()
        logger.info(f"Gemini response: {text_response[:200]}...")

        # Remove markdown code blocks if present
        if text_response.startswith('```json'):
            text_response = text_response[7:]
        if text_response.endswith('```'):
            text_response = text_response[:-3]

        text_response = text_response.strip()

        # Parse JSON
        try:
            workout_plan = json.loads(text_response)
            logger.info("Successfully parsed workout plan from Gemini")
            return workout_plan
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Gemini: {e}")
            logger.error(f"Response text: {text_response}")
            raise ValueError(f"Invalid JSON response from AI: {e}")

    except Exception as e:
        logger.error(f"Error in Gemini service: {str(e)}")
        # Return fallback workout plan
        return {
            "weekly_split": "Basic full-body routine",
            "days": [
                {
                    "day": "Monday",
                    "focus": "Full Body",
                    "duration_minutes": 60,
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": "10-15",
                            "rest_seconds": 90,
                            "notes": "Modify on knees if needed"
                        },
                        {
                            "name": "Bodyweight Squats",
                            "sets": 3,
                            "reps": "15-20",
                            "rest_seconds": 60,
                            "notes": "Keep chest up, go as low as comfortable"
                        },
                        {
                            "name": "Plank",
                            "sets": 3,
                            "reps": "20-30 seconds",
                            "rest_seconds": 60,
                            "notes": "Keep body straight, engage core"
                        }
                    ],
                    "warmup": "5 minutes light cardio (jumping jacks, marching in place)",
                    "cooldown": "5 minutes stretching focusing on worked muscles"
                },
                {
                    "day": "Wednesday",
                    "focus": "Full Body",
                    "duration_minutes": 60,
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": "10-15",
                            "rest_seconds": 90,
                            "notes": "Focus on full range of motion"
                        },
                        {
                            "name": "Lunges",
                            "sets": 3,
                            "reps": "10 per leg",
                            "rest_seconds": 60,
                            "notes": "Alternate legs, keep front knee over ankle"
                        },
                        {
                            "name": "Superman",
                            "sets": 3,
                            "reps": "10-15",
                            "rest_seconds": 60,
                            "notes": "Lift arms and legs off ground, squeeze back"
                        }
                    ],
                    "warmup": "5 minutes light cardio and dynamic stretches",
                    "cooldown": "5 minutes static stretching"
                },
                {
                    "day": "Friday",
                    "focus": "Full Body",
                    "duration_minutes": 60,
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": "12-15",
                            "rest_seconds": 90,
                            "notes": "Increase reps as you get stronger"
                        },
                        {
                            "name": "Squats",
                            "sets": 3,
                            "reps": "15-20",
                            "rest_seconds": 60,
                            "notes": "Add jump for more intensity if ready"
                        },
                        {
                            "name": "Mountain Climbers",
                            "sets": 3,
                            "reps": "20 per leg",
                            "rest_seconds": 60,
                            "notes": "Keep core engaged, alternate quickly"
                        }
                    ],
                    "warmup": "5 minutes cardio and arm circles",
                    "cooldown": "5 minutes full body stretching"
                }
            ]
        }

async def generate_meal_plan(user_data, preferences):
    """
    Generate a personalized meal plan using Google Gemini AI

    Args:
        user_data (dict): User metrics including age, gender, height, weight, BMI, goal, activity_level
        preferences (dict): Diet preferences including food_preference, allergies, meals_per_day

    Returns:
        dict: Structured meal plan in JSON format
    """
    try:
        # Generate unique seed for this session to ensure different plans
        unique_seed = f"{int(time.time() * 1000)}_{random.randint(1000, 9999)}"

        # Log the received preferences for debugging
        logger.info(f"Received meal preferences - food_preference: {preferences.get('food_preference', 'veg')}, allergies: {preferences.get('allergies', [])}, meals_per_day: {preferences.get('meals_per_day', 3)}")

        # Determine BMI category
        bmi = user_data.get('bmi', 22.5)
        if bmi < 18.5:
            bmi_category = "Underweight"
        elif bmi < 25:
            bmi_category = "Normal weight"
        elif bmi < 30:
            bmi_category = "Overweight"
        else:
            bmi_category = "Obese"

        # Goal and Activity Level for calculations
        goal = ", ".join(user_data.get('goals', [])) if user_data.get('goals') else user_data.get('goal', 'General Fitness')
        activity_level = user_data.get('activity_level', 'Moderately Active')
        
        # Macro ratios
        if goal in ['Muscle Gain', 'General Fitness']:
            protein_ratio, carb_ratio, fat_ratio = 0.25, 0.45, 0.30
        elif goal in ['Weight Loss', 'Fat Loss']:
            protein_ratio, carb_ratio, fat_ratio = 0.30, 0.40, 0.30
        else:
            protein_ratio, carb_ratio, fat_ratio = 0.20, 0.50, 0.30

        # Activity multipliers
        activity_multipliers = {
            'Sedentary': 1.2,
            'Lightly Active': 1.375,
            'Moderately Active': 1.55,
            'Very Active': 1.725,
            'Extremely Active': 1.9
        }

        # Build comprehensive prompt with unique seed
        prompt = f"""
Generate a COMPLETELY UNIQUE personalized daily meal plan in JSON format with varied Indian food options.

SESSION ID: {unique_seed} - YOU MUST GENERATE A PLAN THAT IS DIFFERENT FROM ANY PREVIOUS ONES.
DO NOT REPEAT THE SAME MEALS. VARIETY IS CRITICAL.

USER PROFILE:
- Age: {user_data.get('age', 25)}, Gender: {user_data.get('gender', 'Male')}
- Height: {user_data.get('height', 170)}cm, Weight: {user_data.get('weight', 70)}kg, BMI: {bmi:.1f} ({bmi_category})
- Goal: {goal}, Activity: {activity_level}

PREFERENCES:
- Food Type: {preferences.get('food_preference', 'veg')}
- Daily Foods (must include if possible): {", ".join(preferences.get('daily_foods', [])) if preferences.get('daily_foods') else "None specific"}
- Allergies (MUST AVOID): {", ".join(preferences.get('allergies', [])) if preferences.get('allergies') else "None"}
- Meals per Day: {preferences.get('meals_per_day', 3)}

CALCULATION METHOD:
BMR = {10 * user_data.get('weight', 70) + 6.25 * user_data.get('height', 170) - 5 * user_data.get('age', 25) + (5 if user_data.get('gender', 'Male').lower() == 'male' else -161):.0f} calories
TDEE = BMR × {activity_multipliers.get(activity_level, 1.55):.3f} = {(10 * user_data.get('weight', 70) + 6.25 * user_data.get('height', 170) - 5 * user_data.get('age', 25) + (5 if user_data.get('gender', 'Male').lower() == 'male' else -161)) * activity_multipliers.get(activity_level, 1.55):.0f} calories

TARGET CALORIES: {user_data.get('calories_goal') if user_data.get('calories_goal') else f"Adjust TDEE by goal ({goal}) for optimal results."} (Strictly aim to make daily_calories close to this)

MACROS: {protein_ratio*100:.0f}% Protein, {carb_ratio*100:.0f}% Carbs, {fat_ratio*100:.0f}% Fats

REQUIREMENTS:
- Create {preferences.get('meals_per_day', 3)} meals with specific quantities
- Respect food preference and STRICTLY AVOID allergies
- MUST incorporate the provided 'Daily Foods' reasonably across the meals
- Portion Sizes: ALWAYS use Grams (g) for food quantities (e.g., "150g") instead of subjective units like "cups", "servings", or "bowls".
- Include traditional Indian foods with modern nutrition (e.g. Millet-based foods, varied protein sources)
- Balance nutrition based on goal and activity level
- VARIETY RULE: Choose different dishes, spices, and ingredients for every single response.
- Return ONLY valid JSON, no additional text

{{
  "daily_calories": target_calories,
  "macros": {{"protein": "Xg", "carbs": "Yg", "fats": "Zg"}},
  "meals": [
    {{
      "type": "Meal Type",
      "items": [{{"name": "Food Item", "quantity": "specific amount"}}],
      "calories": meal_calories,
      "description": "goal-specific description"
    }}
  ]
}}

Generate unique plan for session {unique_seed}:
"""

        # Generate response using retry logic
        logger.info("Calling Gemini AI (gemini-2.5-flash-lite) for meal plan generation")
        response = get_model_response('gemini-2.5-flash-lite', prompt)

        if not response or not response.text:
            logger.error("No response from Gemini AI")
            raise ValueError("No response from AI service")

        # Clean and parse JSON response
        text_response = response.text.strip()
        
        # Remove markdown code blocks if present
        if text_response.startswith('```json'):
            text_response = text_response[7:]
        if text_response.endswith('```'):
            text_response = text_response[:-3]

        text_response = text_response.strip()

        # Parse JSON
        try:
            meal_plan = json.loads(text_response)
            logger.info("Successfully parsed meal plan from Gemini")
            return meal_plan
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Gemini: {e}")
            raise ValueError(f"Invalid JSON response from AI: {e}")

    except Exception as e:
        logger.error(f"Error in Gemini meal service: {str(e)}")
        # Return personalized fallback meal plan
        return {
            "daily_calories": 2000,
            "macros": {"protein": "120g", "carbs": "220g", "fats": "60g"},
            "meals": [
                {
                    "type": "Breakfast",
                    "items": [{"name": "Oats", "quantity": "80g"}, {"name": "Milk", "quantity": "250g"}],
                    "calories": 400,
                    "description": "Quick high-protein breakfast"
                },
                {
                    "type": "Lunch",
                    "items": [{"name": "Rice", "quantity": "150g"}, {"name": "Dal", "quantity": "200g"}],
                    "calories": 600,
                    "description": "Balanced lunch"
                },
                {
                    "type": "Dinner",
                    "items": [{"name": "Roti", "quantity": "2 pieces"}, {"name": "Sabzi", "quantity": "180g"}],
                    "calories": 500,
                    "description": "Light dinner"
                }
            ]
        }

async def analyze_blood_report(file_data, mime_type, user_data):
    """
    Analyze blood report image/PDF and suggest supplements based on markers.
    """
    try:
        goal = ", ".join(user_data.get('goals', [])) if user_data.get('goals') else user_data.get('goal', 'General Fitness')
        
        # Build prompt for multimodal analysis
        prompt = f"""
You are an expert clinical nutritionist and medical report analyst. 
Examine this blood report and provide supplement recommendations based on the detected markers and the user's fitness goals ({goal}).

User Profile:
- Age: {user_data.get('age', 25)}, Gender: {user_data.get('gender', 'Male')}

Instructions:
1. Identify any deficiencies or sub-optimal levels (e.g. Low Vitamin D, B12, Iron, etc.) from the report.
2. Suggest 2-3 targeted supplements ONLY if the report indicates a need.
3. Explain the "Why" using specific values found in the report.
4. Keep the output very minimal and clinical.
5. Return ONLY valid JSON.

Required JSON Structure:
{{
  "report_summary": "Short summary of findings (e.g. Vitamin D is at 15ng/ml which is low)",
  "recommendations": [
    {{
      "name": "Supplement Name",
      "dosage": "Amount",
      "timing": "When to take",
      "reason": "Based on report value X..."
    }}
  ],
  "is_clinical": true
}}

Return ONLY valid JSON:
"""
        # Create part for the file
        parts = [
            {"inline_data": {"mime_type": mime_type, "data": file_data}},
            prompt
        ]

        # Generate response using retry logic
        logger.info(f"Calling Gemini AI (gemini-2.5-flash-lite) for blood report analysis (type: {mime_type})")
        response = get_model_response('gemini-2.5-flash-lite', parts)

        if not response or not response.text:
            raise ValueError("No response from AI")

        # Clean and parse JSON
        text_response = response.text.strip()
        if text_response.startswith('```json'):
            text_response = text_response[7:]
        if text_response.endswith('```'):
            text_response = text_response[:-3]
        
        return json.loads(text_response.strip())

    except Exception as e:
        logger.error(f"Error in blood report analysis: {str(e)}")
        return {
            "report_summary": "Error analyzing report. Please ensure the image is clear and readable.",
            "recommendations": [],
            "is_clinical": False
        }

async def generate_supplements(user_data):
    """
    Generate personalized supplement suggestions using Google Gemini AI
    """
    try:
        # Determine BMI category for added context
        # Handle both dict and object types for user_data
        if hasattr(user_data, 'dict'):
             user_data_dict = user_data.dict()
        elif isinstance(user_data, dict):
             user_data_dict = user_data
        else:
             user_data_dict = {}

        bmi = user_data_dict.get('bmi', 22.5)
        goal_list = user_data_dict.get('goals', [])
        goal_str = ", ".join(goal_list) if goal_list else user_data_dict.get('goal', 'General Fitness')
        
        prompt = f"""
You are a professional sports nutritionist. Suggest a personalized supplement stack for this user in JSON format only.

User Profile:
- Age: {user_data_dict.get('age', 25)}
- Gender: {user_data_dict.get('gender', 'Male')}
- BMI: {bmi:.1f}
- Fitness Goals: {goal_str}
- Training Level: {user_data_dict.get('gym_level', 'Beginner')}
- Activity Level: {user_data_dict.get('activity_level', 'Moderately Active')}

Instructions:
1. Suggest 3-4 essential, safe supplements.
2. For each, provide a very concise dosage, timing, and a one-sentence benefit.
3. Keep descriptions extremely short (max 10 words).
4. Provide a brief safety disclaimer.
5. Return ONLY valid JSON.

Required JSON Structure:
{{
  "supplements": [
    {{
      "name": "Supplement Name",
      "dosage": "e.g. 5g",
      "timing": "e.g. Post-workout",
      "benefit": "Why this helps",
      "description": "Brief explanation"
    }}
  ],
  "safety_disclaimer": "Consult with a doctor..."
}}

Return ONLY valid JSON:
"""

        # Generate response using retry logic
        logger.info(f"Calling Gemini AI (gemini-2.5-flash-lite) for supplement suggestions for {user_data_dict.get('name', 'Unknown')}")
        response = get_model_response('gemini-2.5-flash-lite', prompt)

        if not response or not response.text:
            logger.error("Empty response from AI service")
            raise ValueError("No response from AI service")

        # Clean and parse JSON response
        text_response = response.text.strip()
        if text_response.startswith('```json'):
            text_response = text_response[7:]
        if text_response.endswith('```'):
            text_response = text_response[:-3]

        text_response = text_response.strip()

        try:
            suggestions = json.loads(text_response)
            logger.info("Successfully synthesized supplement stack")
            return suggestions
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse supplement JSON: {e}")
            logger.debug(f"Raw response: {text_response}")
            raise ValueError(f"Invalid JSON from AI: {e}")

    except Exception as e:
        logger.error(f"CRITICAL: Supplement Synthesis Failed: {str(e)}")
        # Return fallback supplements
        return {
            "supplements": [
                {
                    "name": "Multivitamin",
                    "dosage": "1 tablet",
                    "timing": "With breakfast",
                    "benefit": "Ensures overall micronutrient balance for recovery",
                    "description": "A blend of essential vitamins and minerals."
                },
                {
                    "name": "Fish Oil",
                    "dosage": "1000mg",
                    "timing": "With lunch",
                    "benefit": "Supports joint health and reduces inflammation",
                    "description": "Rich in Omega-3 fatty acids."
                }
            ],
            "safety_disclaimer": "Safety first: Please consult a healthcare professional before adding supplements to your routine."
        }