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
    is_verified = models.BooleanField(default=False)
    verification_code = models.CharField(max_length=6, blank=True, null=True)
    is_online = models.BooleanField(default=False)  
    last_seen = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.username} ({self.role})"

class TutorProfile(models.Model):
    DEPARTMENT_CHOICES = [
        ('Computer Science', 'Computer Science'),
        ('Computer Engineering', 'Computer Engineering'),
    ]
    
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutor_profile')
    subject = models.CharField(max_length=50, default="Not Specified")
    year = models.CharField(max_length=20, default="Unknown")
    semester = models.CharField(max_length=20, default="Unknown")
    department = models.CharField(max_length=50, choices=DEPARTMENT_CHOICES, default="Computer Science")
    available = models.BooleanField(default=True)
    rate = models.CharField(max_length=20, default="Not Provided")  # Hourly rate
    account_number = models.CharField(max_length=20, default="Not Provided") 
    profile_picture = models.ImageField(upload_to='tutor_profiles/pictures/', null=True, blank=True)
    
    def __str__(self):
        return f"{self.user.username} - {self.subject}"

class TuteeProfile(models.Model):
    DEPARTMENT_CHOICES = [
        ('Computer Science', 'Computer Science'),
        ('Computer Engineering', 'Computer Engineering'),
    ]
    
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutee_profile')
    year = models.CharField(max_length=20, default="Unknown")
    semester = models.CharField(max_length=20, default="Unknown")
    department = models.CharField(max_length=50, choices=DEPARTMENT_CHOICES, default="Computer Science")
    profile_picture = models.ImageField(upload_to='tutor_profiles/pictures/', null=True, blank=True)
    
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

class Availability(models.Model):
    """
    Tutor's available time slots on specific dates
    """
    STATUS_CHOICES = [
        ('Available', 'Available'),
        ('Booked', 'Booked'),
        ('Unavailable', 'Unavailable'),
    ]
    
    tutor = models.ForeignKey(TutorProfile, on_delete=models.CASCADE, related_name='availabilities', null=True, blank=True)
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='Available')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['date', 'start_time']
        unique_together = ['tutor', 'date', 'start_time']
    
    def __str__(self):
        return f"{self.tutor.user.username} - {self.date} {self.start_time}-{self.end_time} ({self.status})"
    
    def formatted_time(self):
        """Returns formatted time string like '2 PM - 3 PM'"""
        return f"{self.start_time.strftime('%I:%M %p')} - {self.end_time.strftime('%I:%M %p')}"
    
    def formatted_date(self):
        """Returns formatted date string"""
        return self.date.strftime('%B %d, %Y')
    
    def day_name(self):
        """Returns day name like 'Monday'"""
        return self.date.strftime('%A')

class Booking(models.Model):
    """
    Represents a booking/session between a tutor and tutee
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    availability = models.OneToOneField(
        Availability, 
        on_delete=models.CASCADE, 
        related_name='booking'
    )
    tutee = models.ForeignKey(
        TuteeProfile, 
        on_delete=models.CASCADE, 
        related_name='bookings'
    )
    is_demo = models.BooleanField(default=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    booked_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-booked_at']
    
    def __str__(self):
        tutor_name = self.availability.tutor.user.username
        tutee_name = self.tutee.user.username
        return f"{tutee_name} -> {tutor_name} on {self.availability.date}"
    
    @property
    def tutor_profile(self):
        return self.availability.tutor
    
    @property
    def subject(self):
        return self.availability.tutor.subject

class UpdateLastSeenMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.user.is_authenticated:
            request.user.last_seen = timezone.now()
            request.user.save(update_fields=['last_seen'])
        return self.get_response(request)