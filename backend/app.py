import logging
from flask import Flask
from flask_cors import CORS
from config import Config
from routes import api


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app, origins=Config.CORS_ORIGINS)

    logging.basicConfig(
        level=getattr(logging, Config.LOG_LEVEL, logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    app.register_blueprint(api)

    @app.route("/")
    def index():
        return {
            "service": "Employee Management API",
            "version": "1.0.0",
            "endpoints": {
                "health": "/api/health",
                "employees": "/api/employees",
                "departments": "/api/departments",
                "projects": "/api/projects",
                "stats": "/api/stats",
            },
        }

    @app.errorhandler(404)
    def not_found(error):
        return {"error": "Not found"}, 404

    @app.errorhandler(500)
    def internal_error(error):
        return {"error": "Internal server error"}, 500

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)