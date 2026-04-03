import google.genai as genai
from app.core.config import settings
import json
import logging
import time
import random

logger = logging.getLogger(__name__)

# Initialize the client
client = genai.Client(api_key=settings.gemini_api_key)

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
- Fitness Goal: {user_data.get('goal', 'General Fitness')}
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

        # Initialize Gemini model
        try:
            # List available models for debugging
            models = client.models.list()
            available_models = [model.name for model in models if 'generateContent' in model.supported_generation_methods]
            logger.info(f"Available models with generateContent: {available_models}")
        except Exception as e:
            logger.error(f"Error listing models: {e}")

        # Generate response
        logger.info("Calling Gemini AI for workout plan generation")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )

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

        # Build comprehensive prompt with unique seed
        prompt = f"""
Generate a UNIQUE personalized daily meal plan in JSON format with Indian food options.

SESSION: {unique_seed}

USER PROFILE:
- Age: {user_data.get('age', 25)}, Gender: {user_data.get('gender', 'Male')}
- Height: {user_data.get('height', 170)}cm, Weight: {user_data.get('weight', 70)}kg, BMI: {bmi:.1f} ({bmi_category})
- Goal: {user_data.get('goal', 'General Fitness')}, Activity: {user_data.get('activity_level', 'Moderately Active')}

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
- Include traditional Indian foods with modern nutrition
- Balance nutrition based on goal and activity level
- Return ONLY valid JSON

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

        # Initialize Gemini model
        try:
            # List available models for debugging
            models = client.models.list()
            available_models = [model.name for model in models if 'generateContent' in model.supported_generation_methods]
            logger.info(f"Available models with generateContent: {available_models}")
        except Exception as e:
            logger.error(f"Error listing models: {e}")

        # Generate response
        logger.info("Calling Gemini AI for meal plan generation")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )

        if not response or not response.text:
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
            meal_plan = json.loads(text_response)
            logger.info("Successfully parsed meal plan from Gemini")
            return meal_plan
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Gemini: {e}")
            logger.error(f"Response text: {text_response}")
            raise ValueError(f"Invalid JSON response from AI: {e}")

    except Exception as e:
        logger.error(f"Error in Gemini meal service: {str(e)}")
        # Return personalized fallback meal plan that respects preferences and user metrics
        food_pref = preferences.get('food_preference', 'veg')
        allergies = preferences.get('allergies', [])
        meals_per_day = preferences.get('meals_per_day', 3)

        # Calculate personalized calories based on user goals
        goal = user_data.get('goal', 'General Fitness')
        activity_level = user_data.get('activity_level', 'Moderately Active')
        bmi = user_data.get('bmi', 22.5)
        age = user_data.get('age', 25)
        gender = user_data.get('gender', 'Male')
        height = user_data.get('height', 170)
        weight = user_data.get('weight', 70)

        # BMR calculation
        if gender.lower() == 'male':
            bmr = 10 * weight + 6.25 * height - 5 * age + 5
        else:
            bmr = 10 * weight + 6.25 * height - 5 * age - 161

        # Activity multipliers
        activity_multipliers = {
            'Sedentary': 1.2,
            'Lightly Active': 1.375,
            'Moderately Active': 1.55,
            'Very Active': 1.725,
            'Extremely Active': 1.9
        }

        tdee = bmr * activity_multipliers.get(activity_level, 1.55)

        # Goal-based calorie adjustments
        goal_calories = {
            'Weight Loss': tdee - 500,
            'Muscle Gain': tdee + 300,
            'General Fitness': tdee,
            'Weight Maintenance': tdee,
            'Fat Loss': tdee - 500,
            'Endurance Training': tdee + 200
        }

        if user_data.get('calories_goal'):
            target_calories = user_data.get('calories_goal')
        else:
            target_calories = goal_calories.get(goal, tdee)
            target_calories = max(1200, min(4000, target_calories))  # Clamp between 1200-4000 calories

        # Base meal structures with personalized portions
        if food_pref == 'veg':
            meal_options = [
                {
                    "type": "Breakfast",
                    "items": [
                        {"name": "Oats", "quantity": f"{min(80, target_calories // 20)}g"},
                        {"name": "Milk", "quantity": "1 cup"},
                        {"name": "Banana", "quantity": "1 medium"},
                        {"name": "Almonds", "quantity": f"{min(15, target_calories // 60)} pieces"}
                    ],
                    "calories": min(450, target_calories // 4),
                    "description": f"High-protein breakfast optimized for {goal} with complex carbs and healthy fats"
                },
                {
                    "type": "Lunch",
                    "items": [
                        {"name": "Brown Rice", "quantity": f"{min(150, target_calories // 15)}g"},
                        {"name": "Dal", "quantity": "1 cup"},
                        {"name": "Mixed Vegetables", "quantity": f"{min(250, target_calories // 8)}g"},
                        {"name": "Curd", "quantity": f"{min(150, target_calories // 13)}g"}
                    ],
                    "calories": min(550, target_calories // 3),
                    "description": f"Balanced lunch with lean protein and fiber-rich vegetables for sustained energy during {activity_level.lower()} activity"
                },
                {
                    "type": "Dinner",
                    "items": [
                        {"name": "Roti", "quantity": f"{min(3, target_calories // 150)} pieces"},
                        {"name": "Paneer Sabzi", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Green Salad", "quantity": "1 bowl"}
                    ],
                    "calories": min(500, target_calories // 3),
                    "description": f"Light dinner with high-quality protein for muscle recovery and repair supporting {goal}"
                },
                {
                    "type": "Snack",
                    "items": [
                        {"name": "Greek Yogurt", "quantity": f"{min(150, target_calories // 13)}g"},
                        {"name": "Fruits", "quantity": "1 cup"},
                        {"name": "Nuts", "quantity": f"{min(20, target_calories // 40)}g"}
                    ],
                    "calories": min(250, target_calories // 8),
                    "description": f"Nutrient-dense snack providing sustained energy and supporting {goal} goals"
                }
            ]
        elif food_pref == 'non-veg':
            meal_options = [
                {
                    "type": "Breakfast",
                    "items": [
                        {"name": "Eggs", "quantity": f"{min(3, target_calories // 150)} pieces"},
                        {"name": "Whole Wheat Bread", "quantity": f"{min(3, target_calories // 100)} slices"},
                        {"name": "Chicken Sausage", "quantity": f"{min(50, target_calories // 40)}g"}
                    ],
                    "calories": min(500, target_calories // 4),
                    "description": f"High-protein breakfast with complete amino acids to support {goal} and muscle maintenance"
                },
                {
                    "type": "Lunch",
                    "items": [
                        {"name": "Chicken Curry", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Rice", "quantity": f"{min(150, target_calories // 15)}g"},
                        {"name": "Mixed Vegetables", "quantity": f"{min(250, target_calories // 8)}g"}
                    ],
                    "calories": min(600, target_calories // 3),
                    "description": f"Lean protein-focused lunch optimized for post-workout recovery and {activity_level.lower()} lifestyle"
                },
                {
                    "type": "Dinner",
                    "items": [
                        {"name": "Grilled Fish", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Roti", "quantity": f"{min(3, target_calories // 150)} pieces"},
                        {"name": "Salad", "quantity": "1 bowl"}
                    ],
                    "calories": min(550, target_calories // 3),
                    "description": f"Omega-3 rich dinner supporting heart health and recovery for {goal} goals"
                },
                {
                    "type": "Snack",
                    "items": [
                        {"name": "Boiled Eggs", "quantity": f"{min(2, target_calories // 150)} pieces"},
                        {"name": "Fruits", "quantity": "1 medium"}
                    ],
                    "calories": min(200, target_calories // 8),
                    "description": f"Quick protein boost to maintain muscle mass during {goal}"
                }
            ]
        elif food_pref == 'vegan':
            meal_options = [
                {
                    "type": "Breakfast",
                    "items": [
                        {"name": "Oatmeal", "quantity": f"{min(80, target_calories // 20)}g"},
                        {"name": "Plant-based Milk", "quantity": "1 cup"},
                        {"name": "Chia Seeds", "quantity": f"{min(15, target_calories // 60)}g"},
                        {"name": "Fruits", "quantity": "1 cup"}
                    ],
                    "calories": min(450, target_calories // 4),
                    "description": f"Plant-based breakfast with complete protein sources for {goal} and sustained energy"
                },
                {
                    "type": "Lunch",
                    "items": [
                        {"name": "Quinoa", "quantity": f"{min(150, target_calories // 15)}g"},
                        {"name": "Chickpea Curry", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Mixed Vegetables", "quantity": f"{min(250, target_calories // 8)}g"}
                    ],
                    "calories": min(550, target_calories // 3),
                    "description": f"Complete protein lunch with fiber-rich vegetables supporting {activity_level.lower()} activity levels"
                },
                {
                    "type": "Dinner",
                    "items": [
                        {"name": "Brown Rice", "quantity": f"{min(150, target_calories // 15)}g"},
                        {"name": "Tofu Stir Fry", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Green Salad", "quantity": "1 bowl"}
                    ],
                    "calories": min(500, target_calories // 3),
                    "description": f"Plant-based dinner with antioxidants and phytonutrients for recovery and {goal}"
                },
                {
                    "type": "Snack",
                    "items": [
                        {"name": "Mixed Nuts", "quantity": f"{min(30, target_calories // 30)}g"},
                        {"name": "Fresh Fruits", "quantity": "1 cup"}
                    ],
                    "calories": min(250, target_calories // 8),
                    "description": f"Healthy fats and micronutrients to support overall health during {goal}"
                }
            ]
        else:  # eggitarian
            meal_options = [
                {
                    "type": "Breakfast",
                    "items": [
                        {"name": "Eggs", "quantity": f"{min(3, target_calories // 150)} pieces"},
                        {"name": "Toast", "quantity": f"{min(3, target_calories // 100)} slices"},
                        {"name": "Avocado", "quantity": f"{min(50, target_calories // 40)}g"}
                    ],
                    "calories": min(500, target_calories // 4),
                    "description": f"Nutrient-dense breakfast with healthy fats for brain function and {goal} support"
                },
                {
                    "type": "Lunch",
                    "items": [
                        {"name": "Rice", "quantity": f"{min(150, target_calories // 15)}g"},
                        {"name": "Egg Curry", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Vegetables", "quantity": f"{min(250, target_calories // 8)}g"}
                    ],
                    "calories": min(550, target_calories // 3),
                    "description": f"Balanced lunch with complete proteins and vegetables for {activity_level.lower()} energy needs"
                },
                {
                    "type": "Dinner",
                    "items": [
                        {"name": "Roti", "quantity": f"{min(3, target_calories // 150)} pieces"},
                        {"name": "Paneer", "quantity": f"{min(200, target_calories // 10)}g"},
                        {"name": "Curd", "quantity": f"{min(150, target_calories // 13)}g"}
                    ],
                    "calories": min(500, target_calories // 3),
                    "description": f"Calcium-rich dinner supporting bone health and muscle recovery for {goal}"
                },
                {
                    "type": "Snack",
                    "items": [
                        {"name": "Boiled Eggs", "quantity": f"{min(2, target_calories // 150)} pieces"},
                        {"name": "Fruits", "quantity": "1 medium"},
                        {"name": "Cheese", "quantity": f"{min(30, target_calories // 100)}g"}
                    ],
                    "calories": min(250, target_calories // 8),
                    "description": f"Balanced snack with protein and healthy fats for sustained energy"
                }
            ]

        # Select meals based on meals_per_day
        selected_meals = meal_options[:meals_per_day]

        # Calculate actual total calories from selected meals
        total_calories = sum(meal['calories'] for meal in selected_meals)

        # Calculate macros based on goal-specific ratios
        if goal in ['Muscle Gain', 'General Fitness']:
            protein_ratio = 0.25
            carb_ratio = 0.45
            fat_ratio = 0.30
        elif goal in ['Weight Loss', 'Fat Loss']:
            protein_ratio = 0.30
            carb_ratio = 0.40
            fat_ratio = 0.30
        else:  # Endurance, Maintenance
            protein_ratio = 0.20
            carb_ratio = 0.50
            fat_ratio = 0.30

        return {
            "daily_calories": total_calories,
            "macros": {
                "protein": f"{total_calories * protein_ratio // 4}g",
                "carbs": f"{total_calories * carb_ratio // 4}g",
                "fats": f"{total_calories * fat_ratio // 9}g"
            },
            "meals": selected_meals
        }