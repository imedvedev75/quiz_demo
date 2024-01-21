from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, auth, firestore

app = Flask(__name__)
CORS(app)

# Initialize Firebase Admin SDK
cred = credentials.Certificate("quiz-sak.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def verify_token(token):
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except ValueError:
        # Token is invalid
        return None

@app.route('/', methods=['GET'])
def root():
    return jsonify({"msg": "Hi there!"}), 200


def validate_quiz(quiz_json):
    if not quiz_json.get('description', '').strip():
        return 'Quiz description is not filled.'

    questions = quiz_json.get('questions', [])

    if not 1 <= len(questions) <= 10:
        return 'Number of questions should be between 1 and 10.'

    for index, question in enumerate(questions, start=1):
        if not question.get('text', '').strip():
            return f'The text for Question {index} is not filled.'

        answers = question.get('answers', [])

        if not 1 <= len(answers) <= 5:
            return f'Number of answers for Question {index} should be between 1 and 5.'

        has_correct_answer = any(answer.get('correct', False) for answer in answers)

        if not has_correct_answer and question.get('type', '') != 'QuestionType.multiSelect':
            return f'No correct answer is marked for Question {index}.'

        for ans_index, answer in enumerate(answers, start=1):
            if not answer.get('text', '').strip():
                return f'The text for Answer {ans_index} of Question {index} is not filled.'

    return None

@app.route('/create_quiz', methods=['POST'])
def create_quiz():
    token = request.headers.get('Authorization').split('Bearer ')[1]
    decoded_token = verify_token(token)
    if decoded_token:
        try:
            new_quiz = request.get_json()

            error = validate_quiz(new_quiz)
            if error:
                return jsonify(status="error", message=error), 500

            _, new_quiz_ref = db.collection('quizzes').add(new_quiz)

            return jsonify({"msg": f'New quiz created with ID: {new_quiz_ref.id}'}), 200
        except Exception as e:
            return jsonify(status="error", message=str(e)), 500
    else:
        return jsonify({"msg": "Invalid token!"}), 403


@app.route('/get_quizzes', methods=['GET'])
def get_quizzes():
    token = request.headers.get('Authorization').split('Bearer ')[1]
    decoded_token = verify_token(token)

    if decoded_token:
        uid = decoded_token.get('uid')  # Extract UID from the decoded token
        if not uid:
            return jsonify({"msg": "Cannot find UID in token!"}), 403

        try:
            quizzes_ref = db.collection('quizzes').where('uid', '==', uid).stream()

            # Adjusted this line to include only desired fields and include document ID as 'id'
            quizzes_list = [{
                'id': quiz.id,
                'description': quiz.to_dict().get('description', None),
                'permaUrl': quiz.to_dict().get('permaUrl', None)
            } for quiz in quizzes_ref]

            return jsonify({"quizzes": quizzes_list}), 200
        except Exception as e:
            return jsonify(status="error", message=str(e)), 500
    else:
        return jsonify({"msg": "Invalid token!"}), 403


@app.route('/delete_quiz/<quiz_id>', methods=['DELETE'])
def delete_quiz(quiz_id):
    token = request.headers.get('Authorization').split('Bearer ')[1]
    decoded_token = verify_token(token)

    if decoded_token:
        try:
            # Delete the document by its ID
            db.collection('quizzes').document(quiz_id).delete()

            return jsonify({"msg": f'Quiz with ID: {quiz_id} has been deleted.'}), 200
        except Exception as e:
            return jsonify(status="error", message=str(e)), 500
    else:
        return jsonify({"msg": "Invalid token!"}), 403


@app.route('/get_quiz/<permaUrl>', methods=['GET'])
def get_quiz(permaUrl):
    try:
        quizzes_ref = db.collection('quizzes').where('permaUrl', '==', permaUrl).limit(1).stream()

        quizzes = list(quizzes_ref)
        if quizzes:
            return jsonify({"quiz": quizzes[0].to_dict()}), 200
        else:
            return jsonify({"msg": "Quiz not found!"}), 404
    except Exception as e:
        return jsonify(status="error", message=str(e)), 500


if __name__ == '__main__':
    app.run(debug=True)
