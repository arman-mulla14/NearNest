@echo off
echo =========================================
echo       Starting NearNest on Web
echo =========================================

echo.
echo [1/2] Starting Node.js Backend Server...
start /b cmd /c "cd backend && npm install && npm start"

echo.
echo [2/2] Starting Flutter Web Frontend...
cd frontend && flutter run -d chrome
