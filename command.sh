cd frontend
npm run test
cd ../backend
mypy src
pytest
cd ..
python check_reqs.py

#sonar-start
#sonar-scanner
