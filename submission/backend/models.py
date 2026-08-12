from datetime import datetime


class InMemoryDB:
    """
    A very simple in-memory store.
    A module-level instance is created once at import time and shared by all
    the Flask request handlers, so we don't need a fancy singleton class.
    """

    def __init__(self):
        self._next_id = 4
        self.employees = {
            1: {
                "id": 1, "name": "Alice Johnson", "email": "alice@example.com",
                "phone": "+1-555-0101", "department": "Engineering",
                "designation": "Senior Engineer", "salary": 95000.00,
                "created_at": "2025-01-15T10:00:00Z",
            },
            2: {
                "id": 2, "name": "Bob Smith", "email": "bob@example.com",
                "phone": "+1-555-0102", "department": "Marketing",
                "designation": "Marketing Lead", "salary": 85000.00,
                "created_at": "2025-02-20T10:00:00Z",
            },
            3: {
                "id": 3, "name": "Carol Williams", "email": "carol@example.com",
                "phone": "+1-555-0103", "department": "Human Resources",
                "designation": "HR Manager", "salary": 78000.00,
                "created_at": "2025-03-10T10:00:00Z",
            },
        }
        self.departments = [
            {"id": 1, "name": "Engineering", "employee_count": 1},
            {"id": 2, "name": "Marketing", "employee_count": 1},
            {"id": 3, "name": "Human Resources", "employee_count": 1},
            {"id": 4, "name": "Finance", "employee_count": 0},
            {"id": 5, "name": "Operations", "employee_count": 0},
        ]
        self.projects = [
            {"id": 1, "name": "Project Alpha", "status": "In Progress",
             "team_size": 5, "budget": 250000.00},
            {"id": 2, "name": "Project Beta", "status": "Planning",
             "team_size": 3, "budget": 150000.00},
            {"id": 3, "name": "Project Gamma", "status": "Completed",
             "team_size": 8, "budget": 500000.00},
            {"id": 4, "name": "Project Delta", "status": "On Hold",
             "team_size": 4, "budget": 180000.00},
        ]

    # ---------------- employees ----------------

    def get_all_employees(self):
        return list(self.employees.values())

    def get_employee(self, emp_id):
        return self.employees.get(emp_id)

    def add_employee(self, data):
        emp_id = self._next_id
        self._next_id += 1
        employee = {
            "id": emp_id,
            "name": data.get("name"),
            "email": data.get("email"),
            "phone": data.get("phone"),
            "department": data.get("department"),
            "designation": data.get("designation"),
            "salary": float(data.get("salary", 0)),
            "created_at": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        self.employees[emp_id] = employee
        self._bump_department(employee["department"], +1)
        return employee

    def update_employee(self, emp_id, data):
        employee = self.employees.get(emp_id)
        if not employee:
            return None

        old_dept = employee["department"]
        for field in ("name", "email", "phone", "department", "designation"):
            if data.get(field) is not None:
                employee[field] = data[field]
        if data.get("salary") is not None:
            employee["salary"] = float(data["salary"])

        if employee["department"] != old_dept:
            self._bump_department(old_dept, -1)
            self._bump_department(employee["department"], +1)
        return employee

    def delete_employee(self, emp_id):
        employee = self.employees.pop(emp_id, None)
        if employee:
            self._bump_department(employee["department"], -1)
        return employee

    # ---------------- helpers / read-only endpoints ----------------

    def _bump_department(self, dept_name, delta):
        for dept in self.departments:
            if dept["name"] == dept_name:
                dept["employee_count"] = max(0, dept["employee_count"] + delta)
                return

    def get_departments(self):
        return self.departments

    def get_projects(self):
        return self.projects

    def get_stats(self):
        employees = self.get_all_employees()
        total_salary = sum(e["salary"] for e in employees)
        return {
            "total_employees": len(employees),
            "total_departments": len(self.departments),
            "total_projects": len(self.projects),
            "total_salary": round(total_salary, 2),
            "avg_salary": round(total_salary / len(employees), 2) if employees else 0,
        }


db = InMemoryDB()
