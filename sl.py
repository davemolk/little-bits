#!/usr/bin/env python3

import requests
import os
import json
from datetime import datetime 


CONFIG_PATH = os.path.join(os.environ['HOME'], ".lunch/config.json")
print(CONFIG_PATH)

def load_config(path):
    with open(path) as f:
        content = f.read()
        data = json.loads(content)
        return data["school_id"], data["grade"]
    
def get_day():
    today = datetime.today()
    if today.weekday() == 5 or today.weekday() == 6:
        print("it's the weekend!")
        exit(1)
    return today
    
def format_date(date):
    return date.strftime("%m%%2F%d%%2F%Y")

def build_url(school_id, grade, date):
    base = "https://webapis.schoolcafe.com/api/CalendarView/GetDailyMenuitemsByGrade?SchoolId="
    return f"{base}{school_id}&ServingDate={date}&ServingLine=Traditional%20Lunch&MealType=Lunch&Grade={grade}&PersonId=null"



school_id, grade = load_config(CONFIG_PATH)
date = format_date(get_day())
url = build_url(school_id, grade, date)
print("checking school lunch...\n\n")
res = requests.get(url)