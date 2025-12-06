from rest_framework import serializers
from .models import Tutor, Tutee, Session
from django.contrib.auth.hashers import make_password

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

class TutorSignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Tutor
        fields = [
            'name', 'email', 'contact', 'semester', 'subject',
            'subjectcode', 'available', 'accountnumber',
            'bankqr', 'password'
        ]

    def create(self, validated_data):
        raw_password = validated_data.pop('password')
        validated_data['password'] = make_password(raw_password)
        return Tutor.objects.create(**validated_data)


class TuteeSignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Tutee
        fields = ['name', 'email', 'contact', 'semester', 'subjectreqd', 'password']

    def create(self, validated_data):
        raw_password = validated_data.pop('password')
        validated_data['password'] = make_password(raw_password)
        return Tutee.objects.create(**validated_data)