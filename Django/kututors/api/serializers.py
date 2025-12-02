from rest_framework import serializers
from .models import Tutor, Tutee, Session

class TutorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tutor
        fields = '__all__'

class TuteeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tutee
        fields = '__all__'

class SessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Session
        fields = '__all__'
