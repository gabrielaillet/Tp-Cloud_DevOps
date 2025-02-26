FROM python:3.11-slim
ENV OPTION_A="Cats"
ENV OPTION_B="Dogs"
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["flask", "run", "--debug"]