FROM python:3.9-slim
RUN apt-get update && apt-get install -y apache2-utils
COPY make-data.py ./
COPY generate-votes.sh ./ 
RUN python make-data.py
RUN chmod +x generate-votes.sh
CMD ["./generate-votes.sh"]