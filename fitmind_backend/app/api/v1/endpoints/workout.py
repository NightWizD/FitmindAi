from fastapi import APIRouter, Depends, HTTPException
from app.schemas.workout_plan import TrainingPreferences, WorkoutPlan
from app.services.gemini_service import generate_workout_plan
from app.services.auth_service import get_user_metrics
from app.core.database import get_database
from app.api.dependencies import get_current_user
from bson import ObjectId
from datetime import datetime

router = APIRouter()

@router.get("/list")
async def get_workout_plans(current_user=Depends(get_current_user)):
    db = get_database()
    plans_cursor = db.user_workout_plans.find(
        {"user_id": str(current_user.id)},
        sort=[("created_at", -1)]
    )
    plans = []
    plan_number = 1
    async for plan_doc in plans_cursor:
        name = plan_doc.get("name", f"Workout {plan_number}")
        plans.append({
            "id": str(plan_doc["_id"]),
            "name": name,
            "created_at": plan_doc["created_at"],
            "weekly_split": plan_doc["plan"].get("weekly_split", "General Plan")
        })
        plan_number += 1
    return plans

@router.get("/{plan_id}")
async def get_workout_plan(plan_id: str, current_user=Depends(get_current_user)):
    db = get_database()
    try:
        plan_doc = await db.user_workout_plans.find_one({
            "_id": ObjectId(plan_id),
            "user_id": str(current_user.id)
        })
        if plan_doc:
            return {
                "id": str(plan_doc["_id"]),
                "name": plan_doc.get("name", "Workout Plan"),
                "plan": plan_doc["plan"],
                "created_at": plan_doc["created_at"]
            }
        raise HTTPException(status_code=404, detail="Workout plan not found")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid plan ID")

@router.delete("/{plan_id}")
async def delete_workout_plan(plan_id: str, current_user=Depends(get_current_user)):
    db = get_database()
    try:
        result = await db.user_workout_plans.delete_one({
            "_id": ObjectId(plan_id),
            "user_id": str(current_user.id)
        })
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Workout plan not found")
        return {"message": "Workout plan deleted successfully"}
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid plan ID")

@router.post("/generate", response_model=WorkoutPlan)
async def generate_workout(preferences: TrainingPreferences, current_user=Depends(get_current_user)):
    # Fetch user metrics
    metrics = await get_user_metrics(current_user)
    if not metrics:
        raise HTTPException(status_code=400, detail="User metrics not found. Complete onboarding first.")

    # Fetch user goals
    db = get_database()
    goals_doc = await db.user_goals.find_one({"user_id": str(current_user.id)})
    goals = goals_doc.get("goals", ["General Fitness"]) if goals_doc else ["General Fitness"]

    # Prepare user_data
    height_m = metrics.get("height", 170) / 100
    bmi = metrics.get("weight", 70) / (height_m ** 2) if height_m > 0 else 22.5

    user_data = {
        "age": metrics.get("age", 25),
        "gender": metrics.get("gender", "Male"),
        "height": metrics.get("height", 170),
        "weight": metrics.get("weight", 70),
        "bmi": bmi,
        "goal": goals[0] if goals else "General Fitness",
        "activity_level": metrics.get("activity_level", "Moderately Active")
    }

    # Generate plan
    plan = await generate_workout_plan(user_data, preferences.dict())

    # Store in db
    plan_doc = {
        "user_id": str(current_user.id),
        "plan": plan,
        "preferences": preferences.dict(),
        "created_at": datetime.utcnow()
    }
    await db.user_workout_plans.insert_one(plan_doc)

    return plan
