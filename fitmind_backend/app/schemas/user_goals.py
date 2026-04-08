from pydantic import BaseModel
from typing import List, Optional

class UserGoals(BaseModel):
    goals: List[str]
    weight_goal: Optional[float] = None
    calories_goal: Optional[int] = None
    gym_level: Optional[str] = "Beginner"
