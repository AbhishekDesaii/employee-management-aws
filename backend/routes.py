import logging
from flask import Blueprint, jsonify, request
from models import InMemoryDB

logger = logging.getLogger(__name__)
api = Blueprint("api", __name__, url_prefix="/api")
db = InMemoryDB()


@api.route("/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "employee-management-api",
        "version": "1.0.0",
    }), 200


@api.route("/employees", methods=["GET"])
def get_employees():
    try:
        employees = db.get_all_employees()
        logger.info("Fetched %d employees", len(employees))
        return jsonify(employees), 200
    except Exception as e:
        logger.exception("Failed to fetch employees")
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/employees/<int:emp_id>", methods=["GET"])
def get_employee(emp_id):
    try:
        employee = db.get_employee(emp_id)
        if employee is None:
            return jsonify({"error": "Employee not found"}), 404
        return jsonify(employee), 200
    except Exception as e:
        logger.exception("Failed to fetch employee %d", emp_id)
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/employees", methods=["POST"])
def create_employee():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body is required"}), 400

        required = ["name", "email", "department", "designation"]
        missing = [f for f in required if f not in data or not data[f]]
        if missing:
            return jsonify({
                "error": "Missing required fields",
                "fields": missing,
            }), 400

        employee = db.add_employee(data)
        logger.info("Created employee %d: %s", employee["id"], employee["name"])
        return jsonify(employee), 201
    except Exception as e:
        logger.exception("Failed to create employee")
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/employees/<int:emp_id>", methods=["PUT"])
def update_employee(emp_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body is required"}), 400

        employee = db.update_employee(emp_id, data)
        if employee is None:
            return jsonify({"error": "Employee not found"}), 404

        logger.info("Updated employee %d", emp_id)
        return jsonify(employee), 200
    except Exception as e:
        logger.exception("Failed to update employee %d", emp_id)
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/employees/<int:emp_id>", methods=["DELETE"])
def delete_employee(emp_id):
    try:
        employee = db.delete_employee(emp_id)
        if employee is None:
            return jsonify({"error": "Employee not found"}), 404

        logger.info("Deleted employee %d", emp_id)
        return jsonify({"message": "Employee deleted", "id": emp_id}), 200
    except Exception as e:
        logger.exception("Failed to delete employee %d", emp_id)
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/departments", methods=["GET"])
def get_departments():
    try:
        departments = db.get_departments()
        return jsonify(departments), 200
    except Exception as e:
        logger.exception("Failed to fetch departments")
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/projects", methods=["GET"])
def get_projects():
    try:
        projects = db.get_projects()
        return jsonify(projects), 200
    except Exception as e:
        logger.exception("Failed to fetch projects")
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500


@api.route("/stats", methods=["GET"])
def get_stats():
    try:
        stats = db.get_stats()
        return jsonify(stats), 200
    except Exception as e:
        logger.exception("Failed to fetch stats")
        return jsonify({"error": "Internal server error", "detail": str(e)}), 500