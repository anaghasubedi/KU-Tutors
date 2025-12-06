from rest_framework import serializers
from .models import Tutor, Tutee, Session
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
import random

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

# --- Signup serializers ---
class TutorSignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = Tutor
        fields = [
            'name', 'email', 'contact', 'semester', 'subject',
            'subjectcode', 'available', 'accountnumber',
            'bankqr', 'password', 'confirm_password'
        ]
    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError("Passwords do not match!")
        return data
    def create(self, validated_data):
        # Hash the password
        validated_data.pop('confirm_password')  # remove before saving
        raw_password = validated_data.pop('password')
        validated_data['password'] = make_password(raw_password)

        # Generate 6-digit verification code
        code = str(random.randint(100000, 999999))
        validated_data['verification_code'] = code
        validated_data['is_verified'] = False

        # Create tutor
        tutor = Tutor.objects.create(**validated_data)

        # Send verification code (prints to console in dev)
        subject = 'KU-Tutors Email Verification'
        message = f'Hello {tutor.name},\n\nYour verification code is: {code}\n\nThank you!'
        recipient_list = [tutor.email]
        send_mail(subject, message, None, recipient_list)

        return tutor

class TuteeSignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = Tutee
        fields = [
            'name', 'email', 'contact', 'semester',
            'subjectreqd', 'password', 'confirm_password'
            ]
    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError("Passwords do not match!")
        return data
    def create(self, validated_data):
        # Hash the password
        validated_data.pop('confirm_password')  # remove before saving
        raw_password = validated_data.pop('password')
        validated_data['password'] = make_password(raw_password)

        # Generate 6-digit verification code
        code = str(random.randint(100000, 999999))
        validated_data['verification_code'] = code
        validated_data['is_verified'] = False

        # Create tutee
        tutee = Tutee.objects.create(**validated_data)

        # Send verification code (prints to console in dev)
        subject = 'KU-Tutors Email Verification'
        message = f'Hello {tutee.name},\n\nYour verification code is: {code}\n\nThank you!'
        recipient_list = [tutee.email]
        send_mail(subject, message, None, recipient_list)

        return tutee