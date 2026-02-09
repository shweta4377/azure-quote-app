"""
Random Quote Application
Displays random quotes from Azure SQL Database
"""
import os
import sys
import logging
import pyodbc
from flask import Flask, render_template_string

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Get connection string from environment
SQL_CONNECTION_STRING = os.environ.get('SQL_CONNECTION_STRING')

if not SQL_CONNECTION_STRING:
    logger.error("SQL_CONNECTION_STRING environment variable not set!")
    sys.exit(1)

def get_db_connection():
    """Create database connection"""
    try:
        conn = pyodbc.connect(SQL_CONNECTION_STRING, timeout=30)
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise

def get_random_quote():
    """Fetch a random quote from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT TOP 1 quote_text, author, category
            FROM quotes
            ORDER BY NEWID()
        """)

        row = cursor.fetchone()
        cursor.close()
        conn.close()

        if row:
            return row.quote_text, row.author, row.category
        else:
            return None, None, None

    except Exception as e:
        logger.error(f"Error fetching quote: {e}")
        return None, None, None

def get_statistics():
    """Get quote statistics"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                COUNT(*) as total_quotes,
                COUNT(DISTINCT author) as total_authors,
                COUNT(DISTINCT category) as total_categories
            FROM quotes
        """)

        row = cursor.fetchone()
        cursor.close()
        conn.close()

        if row:
            return {
                'total_quotes': row.total_quotes,
                'total_authors': row.total_authors,
                'total_categories': row.total_categories
            }
        return {}

    except Exception as e:
        logger.error(f"Error fetching statistics: {e}")
        return {}

# HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Random Quote Generator</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 50px;
            max-width: 800px;
            width: 100%;
            animation: fadeIn 0.6s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        h1 {
            color: #667eea;
            text-align: center;
            margin-bottom: 40px;
            font-size: 2.5em;
        }
        .quote-box {
            background: #f8f9fa;
            border-left: 5px solid #667eea;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            position: relative;
        }
        .quote-icon {
            font-size: 3em;
            color: #667eea;
            opacity: 0.2;
            position: absolute;
            top: 10px;
            left: 10px;
        }
        .quote-text {
            font-size: 1.5em;
            line-height: 1.6;
            color: #333;
            font-style: italic;
            margin-bottom: 20px;
            position: relative;
            z-index: 1;
        }
        .quote-author {
            font-size: 1.2em;
            color: #667eea;
            font-weight: bold;
            text-align: right;
        }
        .quote-category {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 10px;
        }
        .refresh-btn {
            display: block;
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 50px;
            font-size: 1.1em;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            font-weight: bold;
        }
        .refresh-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.4);
        }
        .stats {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #666;
            font-size: 0.9em;
        }
        .error {
            background: #fee;
            border-left-color: #f44;
            color: #c44;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #999;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>💭 Random Quote Generator</h1>

        {% if error %}
        <div class="quote-box error">
            <div class="quote-text">{{ error }}</div>
        </div>
        {% else %}
        <div class="quote-box">
            <div class="quote-icon">"</div>
            <div class="quote-text">{{ quote }}</div>
            <div class="quote-author">— {{ author }}</div>
            {% if category %}
            <div class="quote-category">{{ category }}</div>
            {% endif %}
        </div>
        {% endif %}

        <button class="refresh-btn" onclick="location.reload()">
            🔄 Get Another Quote
        </button>

        {% if stats %}
        <div class="stats">
            📚 {{ stats.total_quotes }} quotes •
            ✍️ {{ stats.total_authors }} authors •
            🏷️ {{ stats.total_categories }} categories
        </div>
        {% endif %}

        <div class="footer">
            Powered by Azure SQL Database + AKS
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    """Main route - display random quote"""
    try:
        quote, author, category = get_random_quote()

        if quote:
            stats = get_statistics()
            return render_template_string(
                HTML_TEMPLATE,
                quote=quote,
                author=author,
                category=category,
                stats=stats
            )
        else:
            return render_template_string(
                HTML_TEMPLATE,
                error="Unable to retrieve quote. Please try again later."
            ), 503

    except Exception as e:
        logger.error(f"Error in index route: {e}")
        return render_template_string(
            HTML_TEMPLATE,
            error="An unexpected error occurred. Please try again later."
        ), 500

@app.route('/health')
def health():
    """Health check endpoint for Kubernetes"""
    try:
        # Test database connectivity
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()

        return {
            'status': 'healthy',
            'database': 'connected',
            'service': 'quote-app'
        }, 200

    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            'status': 'unhealthy',
            'database': 'disconnected',
            'error': str(e)
        }, 503

if __name__ == '__main__':
    logger.info("Starting Quote Application")
    logger.info(f"Connection string configured: {bool(SQL_CONNECTION_STRING)}")

    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=False
    )
