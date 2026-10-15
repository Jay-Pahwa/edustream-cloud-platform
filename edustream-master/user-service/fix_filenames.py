import pymysql
pymysql.install_as_MySQLdb()

import os
from app import app, db, Video

def fix_video_filenames():
    with app.app_context():
        # Update the filenames to match S3
        Video.query.filter_by(title="AWS EC2 Tutorial").update({'s3_key': 'amazon-s3-tutorial-copy.mp4'})
        Video.query.filter_by(title="Amazon S3 Deep Dive").update({'s3_key': 'amazon-s3-deepdive.mp4'})
        Video.query.filter_by(title="Jenkins CI/CD Pipeline").update({'s3_key': 'jenkins-cicd-pipeline.mp4'})
        Video.query.filter_by(title="Docker Containerization").update({'s3_key': 'docker-containerization.mp4'})
        
        db.session.commit()
        print("✅ Database filenames updated!")

if __name__ == '__main__':
    fix_video_filenames()