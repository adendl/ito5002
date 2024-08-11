# RLS policy tests 

This directory contains tests to automatically populate data and test the effectiveness of Row Level Security Policies.

# Requirements

Install dependencies with: `pip install -r requirements.txt`

Tests expect a clean database and may unexpectedly produce failed tests if run on live data.

# Configuration

In additon to the Supabase url, service account key and anon key, testing requires three valid user UUIDs for users that have authenticated to the platorm. The users UUIDs must be stored in the .env file under:

LISTING_USER_ID
BOOKING_USER_ID
ACCESS_USER_ID

Testing also requires the user access token for the "ACCESS_USER_ID", which can be obtained by signing in as the user and obtaining the key from the browser.

# Usage

python3 security_tests.py
