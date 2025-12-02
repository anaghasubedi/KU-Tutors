from django.db import models

class Tutor(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    subject = models.CharField(max_length=50)
    available = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} - {self.subject}"


class Tutee(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    grade = models.CharField(max_length=20)
    subjects_needed = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.name} - {self.grade}"


class Session(models.Model):
    tutor = models.ForeignKey(Tutor, on_delete=models.CASCADE, related_name='sessions')
    tutee = models.ForeignKey(Tutee, on_delete=models.CASCADE, related_name='sessions')
    date = models.DateField()
    time = models.TimeField()
    duration_hours = models.FloatField()
    completed = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.tutor.name} with {self.tutee.name} on {self.date}"


# Create your models here.
