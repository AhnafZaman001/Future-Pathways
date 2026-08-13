from fastapi import APIRouter, Depends

from app.api.deps import CurrentUser, get_current_user

router = APIRouter(prefix="/students", tags=["students"])


@router.get("/me")
def get_my_profile(current_user: CurrentUser = Depends(get_current_user)) -> dict:
    """
    Foundation-milestone shell endpoint: confirms end-to-end auth works
    (frontend -> Supabase session -> bearer token -> verified backend user).

    Does not yet read from student_profiles / student_academic_records —
    that's questionnaire/profile milestone work, not foundation work.
    """
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
    }
