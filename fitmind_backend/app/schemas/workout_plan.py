from pydantic import BaseModel
from typing import List, Union

class Exercise(BaseModel):
    name: str
    sets: Union[int, str]
    reps: Union[int, str]

class Day(BaseModel):
    day: str
    focus: str
    exercises: List[Exercise]

class WorkoutPlan(BaseModel):
    weekly_split: str
    days: List[Day]

class TrainingPreferences(BaseModel):
    gym_access: bool
    days_per_week: int
    hours_per_session: float
    gym_level: str

class DietPreferences(BaseModel):
    food_preference: str  # veg, non-veg, vegan, eggitarian
    allergies: List[str] = []
    meals_per_day: int = 3

class MealPlan(BaseModel):
    daily_calories: int
    macros: dict  # {"protein": "120g", "carbs": "220g", "fats": "60g"}
    meals: List[dict]  # [{"type": "Breakfast", "items": [...], "calories": 350, "description": "..."}]
