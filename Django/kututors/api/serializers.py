from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import TutorProfile, TuteeProfile, Session, TemporarySignup
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
import random

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'contact', 'is_verified']
        read_only_fields = ['id', 'is_verified']

class SignupSerializer(serializers.Serializer):
    name = serializers.CharField()
    email = serializers.EmailField()
    phone_number = serializers.CharField(source='contact')
    role = serializers.CharField()
    password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"password": "Passwords do not match"})
        
        # Check if email already exists in User
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({"email": "Email already registered"})
        
        return data
    
    def create(self, validated_data):
        validated_data.pop('confirm_password')
        name = validated_data.pop('name')
        
        # Generate username from email
        username = validated_data['email'].split('@')[0]
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists() or TemporarySignup.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
        
        # Generate 6-digit verification code
        code = str(random.randint(100000, 999999))
        
        # Hash password before storing temporarily
        hashed_password = make_password(validated_data['password'])
        
        # Delete any existing temporary signup with this email
        TemporarySignup.objects.filter(email=validated_data['email']).delete()
        
        # Create temporary signup
        temp_signup = TemporarySignup.objects.create(
            email=validated_data['email'],
            username=username,
            first_name=name.split()[0] if name else '',
            last_name=' '.join(name.split()[1:]) if len(name.split()) > 1 else '',
            password=hashed_password,
            role=validated_data['role'],
            contact=validated_data.get('contact', ''),
            verification_code=code,
        )
        
        # Send verification email
        try:
            subject = 'KU-Tutors Email Verification'
            message = f'Hello {name},\n\nYour verification code is: {code}\n\nThis code will expire in 15 minutes.\n\nThank you!'
            send_mail(subject, message, None, [temp_signup.email], fail_silently=True)
        except Exception as e:
            print(f"Failed to send email: {e}")
        
        return temp_signup

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class TutorProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    profile_picture_url = serializers.SerializerMethodField()
    
    class Meta:
        model = TutorProfile
        fields = '__all__'
    
    def get_profile_picture_url(self, obj):
        if obj.profile_picture:
            return obj.profile_picture.url
        return None

class TuteeProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    profile_picture_url = serializers.SerializerMethodField()
    
    class Meta:
        model = TuteeProfile
        fields = '__all__'
    
    def get_profile_picture_url(self, obj):
        if obj.profile_picture:
            return obj.profile_picture.url
        return None

class SessionSerializer(serializers.ModelSerializer):
    tutor = TutorProfileSerializer(read_only=True)
    tutee = TuteeProfileSerializer(read_only=True)
    
    class Meta:
        model = Session
        fields = '__all__'

class VerifyEmailSerializer(serializers.Serializer):
    email = serializers.EmailField()
    verification_code = serializers.CharField(max_length=6)

class UpdateProfileSerializer(serializers.Serializer):
    name = serializers.CharField(required=False)
    phone_number = serializers.CharField(required=False)
    subject = serializers.CharField(required=False)  # For tutors
    semester = serializers.CharField(required=False)
    subject_code = serializers.CharField(required=False)  # For tutors
    rate = serializers.CharField(required=False)  # For tutors
    subject_required = serializers.CharField(required=False)  # For tutees