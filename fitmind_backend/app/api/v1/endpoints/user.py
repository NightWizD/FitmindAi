from fastapi import APIRouter, Depends, HTTPException
from app.schemas.user_metrics import UserMetrics, UpdateMetrics
from app.schemas.user_goals import UserGoals
from app.schemas.user_food_preferences import UserFoodPreferences
from app.services.auth_service import save_user_metrics, save_user_goals, update_user_metrics, get_user_metrics, save_user_food_preferences
from app.api.dependencies import get_current_user

router = APIRouter()

@router.get("/metrics")
async def get_metrics(current_user = Depends(get_current_user)):
    metrics = await get_user_metrics(current_user)
    if not metrics:
        raise HTTPException(status_code=404, detail="Metrics not found")
    
    # Also fetch food preferences to include in the response
    from app.services.auth_service import get_user_food_preferences
    food_prefs = await get_user_food_preferences(current_user)
    if food_prefs:
        metrics["food_preference"] = food_prefs.get("food_preference", metrics.get("food_preference", "veg"))
        metrics["daily_foods"] = food_prefs.get("daily_foods", [])
        metrics["allergies"] = food_prefs.get("allergies", metrics.get("allergies", []))
    
    return metrics

@router.post("/metrics")
async def save_metrics(metrics: UserMetrics, current_user = Depends(get_current_user)):
    result = await save_user_metrics(current_user, metrics)
    return {"message": "Metrics saved", "id": str(result)}

@router.post("/goals")
async def save_goals(goals: UserGoals, current_user = Depends(get_current_user)):
    result = await save_user_goals(current_user, goals)
    return {"message": "Goals saved", "id": str(result)}

@router.put("/update-metrics")
async def update_metrics(metrics: UpdateMetrics, current_user = Depends(get_current_user)):
    await update_user_metrics(current_user, metrics.activity_level)
    return {"message": "Metrics updated"}

@router.post("/food-preferences")
async def save_food_preferences(prefs: UserFoodPreferences, current_user = Depends(get_current_user)):
    result = await save_user_food_preferences(current_user, prefs)
    return {"message": "Food preferences saved", "id": str(result)}
from pydantic import BaseModel

class PasswordResetRequest(BaseModel):
    new_password: str

@router.post("/reset-password")
async def reset_password_endpoint(request: PasswordResetRequest, current_user = Depends(get_current_user)):
    from app.services.auth_service import reset_password as reset_pass_service
    await reset_pass_service(current_user, request.new_password)
    return {"message": "Password reset successful"}
