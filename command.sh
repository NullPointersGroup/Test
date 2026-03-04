cd frontend
npm run test
cd ../backend
mypy src
pytest
cd ..
python check_reqs.py

#sonar-start

# carica variabili da sonar.env
#export $(grep -v '^#' sonar.env | xargs)

# lancia SonarQube scanner

#sonar-scanner
