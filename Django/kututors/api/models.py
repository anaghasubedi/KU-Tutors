from django.db import models

class Tutor(models.Model):
    name = models.CharField(max_length=100, primary_key=True)
    email = models.EmailField(unique=True)
    contact = models.CharField(max_length=10,null=True,blank=False)
    subject = models.CharField(max_length=50)
    semester = models.CharField(max_length=20,default="Unknown")
    subject = models.CharField(max_length=50, default="Unknown")
    subjectcode = models.CharField(max_length=10, default="Unknown")
    available = models.BooleanField(default=True)
    accountnumber =models.CharField(max_length=20, default="Not Provided")
    bankqr = models.ImageField(upload_to='Tutor_profile/', default="Not Provided")

    def __str__(self):
        return f"{self.name} - {self.subject}"


class Tutee(models.Model):
    name = models.CharField(max_length=100, primary_key=True)
    email = models.EmailField(unique=True)
    contact = models.CharField(max_length=10,null=True,blank=False)
    semester = models.CharField(max_length=20)
    subjectreqd = models.CharField(max_length=50,default="Unknown")

    def __str__(self):
        return f"{self.name} - {self.semester}"


class Session(models.Model):
    tutor = models.ForeignKey(Tutor, on_delete=models.CASCADE, related_name='sessions')
    tutee = models.ForeignKey(Tutee, on_delete=models.CASCADE, related_name='sessions')
    date = models.DateField()
    time = models.TimeField()
    completed = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.tutor.name} with {self.tutee.name} on {self.date}"


# Create your models here.
