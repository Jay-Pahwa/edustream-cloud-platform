import os
import boto3
from flask import Flask, render_template, request, redirect, url_for, jsonify, flash
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt

app = Flask(__name__)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'

# Environment variables
S3_BUCKET_NAME = "edustream-videos-jayal-1029"

app.config['SECRET_KEY'] = 'edustream_secret_key_2024'

# Initialize AWS S3 client
try:
    s3_client = boto3.client('s3', region_name='ap-south-1')
    print("✅ S3 client initialized successfully")
except Exception as e:
    print(f"❌ S3 Client Error: {e}")
    s3_client = None

# Mock user for testing
class MockUser(UserMixin):
    def __init__(self, id, username):
        self.id = id
        self.username = username

# Hardcoded data for testing
subjects_data = [
    {
        'id': 1,
        'name': 'Cloud Computing',
        'description': 'Master AWS services, cloud architecture, and deployment strategies.',
        'image_url': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&h=400&fit=crop',
        'videos': [
            {'id': 1, 'title': 'AWS EC2 Tutorial', 's3_key': 'aws-ec2-tutorial.mp4'},
            {'id': 2, 'title': 'Amazon S3 Deep Dive', 's3_key': 'amazon-s3-deepdive.mp4'}
        ]
    },
    {
        'id': 2, 
        'name': 'DevOps',
        'description': 'Learn CI/CD pipelines, containerization, and infrastructure automation.',
        'image_url': 'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=600&h=400&fit=crop',
        'videos': [
            {'id': 3, 'title': 'Jenkins CI/CD Pipeline', 's3_key': 'jenkins-cicd-pipeline.mp4'},
            {'id': 4, 'title': 'Docker Containerization', 's3_key': 'docker-containerization.mp4'}
        ]
    }
]

@login_manager.user_loader
def load_user(user_id):
    return MockUser(1, "testuser")  # Always return same user for testing

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Auto-login for testing
        user = MockUser(1, "testuser")
        login_user(user)
        flash('Auto-login successful for testing!', 'success')
        return redirect(url_for('home'))
    return render_template('login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        # Auto-create user for testing
        user = MockUser(1, "testuser")
        login_user(user)
        flash('Auto-signup successful for testing!', 'success')
        return redirect(url_for('home'))
    return render_template('signup.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('login'))

@app.route('/')
@login_required
def home():
    return render_template('index.html', subjects=subjects_data)

@app.route('/subject/<int:subject_id>')
@login_required
def subject_page(subject_id):
    subject = next((s for s in subjects_data if s['id'] == subject_id), None)
    if not subject:
        flash('Subject not found', 'danger')
        return redirect(url_for('home'))
    return render_template('subject_page.html', subject=subject)

@app.route('/video/<int:video_id>')
@login_required
def video_player(video_id):
    # Find video in all subjects
    video = None
    for subject in subjects_data:
        for v in subject['videos']:
            if v['id'] == video_id:
                video = v
                video_subject = subject
                break
        if video:
            break
    
    if not video:
        flash('Video not found', 'danger')
        return redirect(url_for('home'))
    
    # Generate direct S3 URL
    video_url = f"https://{S3_BUCKET_NAME}.s3.ap-south-1.amazonaws.com/{video['s3_key']}"
    print(f"🎯 Video URL: {video_url}")
    
    # Create mock video object for template
    mock_video = type('Video', (), {
        'title': video['title'],
        's3_key': video['s3_key'],
        'subject_id': video_subject['id'],
        'subject': type('Subject', (), {'name': video_subject['name']})()
    })()
    
    return render_template('video_player.html', video=mock_video, video_url=video_url)

@app.route('/api/status')
def status():
    return jsonify({
        "status": "UP", 
        "service": "EduStream Local Test",
        "s3_bucket": S3_BUCKET_NAME
    }), 200

if __name__ == '__main__':
    print("🚀 Starting EduStream LOCAL TEST server on port 8082...")
    print("📝 Using hardcoded data - no database required!")
    app.run(host='0.0.0.0', port=8082, debug=True)