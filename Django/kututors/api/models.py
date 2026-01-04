from django.db import models
from django.contrib.auth.models import AbstractUser
from datetime import timedelta
from django.utils import timezone

class TemporarySignup(models.Model):
    """
    Temporary storage for user signups pending email verification
    """
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150, blank=True)
    password = models.CharField(max_length=128)  # Stores hashed password with salt
    role = models.CharField(max_length=10)
    contact = models.CharField(max_length=10, blank=True)
    verification_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            # Code expires in 15 minutes
            self.expires_at = timezone.now() + timedelta(minutes=15)
        super().save(*args, **kwargs)
    
    def is_expired(self):
        return timezone.now() > self.expires_at
    
    class Meta:
        verbose_name = 'Temporary Signup'
        verbose_name_plural = 'Temporary Signups'
    
    def __str__(self):
        return f"{self.email} - {self.verification_code}"

class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('Tutor', 'Tutor'),
        ('Tutee', 'Tutee'),
    ]
    
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    contact = models.CharField(max_length=10, null=True, blank=True)
    is_verified = models.BooleanField(default=False)  # Changed to False for email verification
    verification_code = models.CharField(max_length=6, blank=True, null=True)
    
    def __str__(self):
        return f"{self.username} ({self.role})"

class TutorProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutor_profile')
    subject = models.CharField(max_length=50, default="Not Specified")
    semester = models.CharField(max_length=20, default="Unknown")
    subjectcode = models.CharField(max_length=10, default="Unknown")
    available = models.BooleanField(default=True)
    accountnumber = models.CharField(max_length=20, default="Not Provided")
    bankqr = models.ImageField(upload_to='tutor_profiles/', null=True, blank=True)  # Can be used for profile pic
    profile_picture = models.ImageField(upload_to='tutor_profiles/pictures/', null=True, blank=True)  # NEW
    
    def __str__(self):
        return f"{self.user.username} - {self.subject}"

class TuteeProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutee_profile')
    semester = models.CharField(max_length=20, default="Not Specified")
    subjectreqd = models.CharField(max_length=50, default="Unknown")
    profile_picture = models.ImageField(upload_to='tutee_profiles/', null=True, blank=True)  # NEW
    
    def __str__(self):
        return f"{self.user.username} - {self.semester}"

class Session(models.Model):
    tutor = models.ForeignKey(TutorProfile, on_delete=models.CASCADE, related_name='sessions')
    tutee = models.ForeignKey(TuteeProfile, on_delete=models.CASCADE, related_name='sessions')
    date = models.DateField()
    time = models.TimeField()
    completed = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.tutor.user.username} with {self.tutee.user.username} on {self.date}"