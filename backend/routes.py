import logging
from flask import Blueprint, jsonify, request
from models import db

logger = logging.getLogger(__name__)
api = Blueprint("api", __name__, url_prefix="/api")

REQUIRED_FIELDS = ["name", "email", "department", "designation"]


@api.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


@api.route("/employees", methods=["GET"])
def list_employees():
    return jsonify(db.get_all_employees()), 200


@api.route("/employees/<int:emp_id>", methods=["GET"])
def get_one(emp_id):
    employee = db.get_employee(emp_id)
    if employee is None:
        return jsonify({"error": "Employee not found"}), 404
    return jsonify(employee), 200


@api.route("/employees", methods=["POST"])
def create():
    data = request.get_json(silent=True) or {}
    missing = [f for f in REQUIRED_FIELDS if not data.get(f)]
    if missing:
        return jsonify({"error": "Missing fields", "fields": missing}), 400
    return jsonify(db.add_employee(data)), 201


@api.route("/employees/<int:emp_id>", methods=["PUT"])
def update(emp_id):
    data = request.get_json(silent=True) or {}
    employee = db.update_employee(emp_id, data)
    if employee is None:
        return jsonify({"error": "Employee not found"}), 404
    return jsonify(employee), 200


@api.route("/employees/<int:emp_id>", methods=["DELETE"])
def delete(emp_id):
    employee = db.delete_employee(emp_id)
    if employee is None:
        return jsonify({"error": "Employee not found"}), 404
    return jsonify({"message": "Employee deleted", "id": emp_id}), 200


@api.route("/departments", methods=["GET"])
def list_departments():
    return jsonify(db.get_departments()), 200


@api.route("/projects", methods=["GET"])
def list_projects():
    return jsonify(db.get_projects()), 200


@api.route("/stats", methods=["GET"])
def stats():
    return jsonify(db.get_stats()), 200
