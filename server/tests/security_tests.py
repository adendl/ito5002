"""
Script to automatically conduct security tests on the server.

Test steps:
 - Uses a service account to populate test data
 - Uses Playwright to obtain authentication JWT
 - Attempts to use JWT to access data in violation of policies 
"""

import httpx
from playwright.sync_api import Playwright, sync_playwright, expect, Route
import logging
import json
from dotenv import load_dotenv
import os
from supabase import create_client, Client
import jwt
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError

httpx_logger = logging.getLogger("httpx")
httpx_logger.setLevel(logging.WARNING)
logging.basicConfig(level=logging.INFO)

class DataIsertException(Exception):
    """
    Custom exception for failed data insertions.
    """

class FailedTest(Exception):
    """
    Custom exception for failed tests.
    """

class DataPopulator():
    """
    Class to populate test data using a 
    Supabase service account.
    """

    def __init__(self):
        """
        Initialise from .env file.
        """
        logging.info("Initialising data populator.")
        load_dotenv(".env.local")
        load_dotenv(".env")
        supabase_url = os.environ.get('PUBLIC_SUPABASE_URL')
        supabase_anon_key = os.environ.get('PUBLIC_SUPABASE_ANON_KEY')
        supabase_service_role_key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
        self.client = create_client(supabase_url, supabase_service_role_key)
        self.listing_user_id = os.environ.get('LISTING_USER_ID')
        self.booking_user_id = os.environ.get('BOOKING_USER_ID')
        self.access_user_id = os.environ.get('ACCESS_USER_ID')
        logging.info("Data populator initialised.")

    def populate_data(self):
        """
        Method to populate test data into relevant tables.
        """
        logging.info("Populating test data.")
        place_id = self.populate_places()
        self.populate_users(place_id)
        self.populate_contacts()
        self.populate_listing(place_id)
        availability_id = self.populate_availability()
        booking_request_id = self.populate_booking_requests(availability_id)
        booking_id = self.populate_booking(availability_id, booking_request_id)
        logging.info("Test data populated.")
        return availability_id, booking_request_id, booking_id

    def populate_places(self):
        """
        Method to populate test data into places table.
        """
        logging.debug("Populating places data.")
        place = {
            "address": "123 Test Street, Testville",
            "point": "POINT(0 0)",
            "suburb": "Testville",
        }
        try:
            selected_place = self.client.table("places").select("*").eq("address", "123 Test Street, Testville").single().execute()
        except Exception as e:
            if "contains 0 rows" in str(e):
                selected_place = None
        if selected_place is None:
            try:
                insert_place = self.client.table("places").insert([place]).execute()
                place_id = insert_place.data[0]["place_id"]
            except Exception as e:
                logging.error(f"Error populating places data: {e}")
                raise DataIsertException("Failed to populate places data.")
        else:
            place_id = selected_place.data["place_id"]
        logging.debug("Places data populated.")
        return place_id

    def populate_users(self, place_id):
        """
        Method to populate test data into users table. Tests
        require three users.
        """
        logging.debug("Populating users data.")
        # user_id is a UUID we need to generate
        users = [
            {
                "user_id": self.listing_user_id,
                "user_name": "Test Listing User",
                "home_place_id": place_id,
                "work_place_id": None,
            },
            {
                "user_id": self.booking_user_id,
                "user_name": "Test Booking User",
                "home_place_id": None,
                "work_place_id": None,
            },
            {
                "user_id": self.access_user_id,
                "user_name": "Test Access User",
                "home_place_id": None,
                "work_place_id": None,
            }
        ]
        try:
            response = self.client.table("users").upsert(users).execute()
        except Exception as e:
            logging.error(f"Error populating users data: {e}")
            raise DataIsertException("Failed to populate users data.")
        logging.debug("Users data populated.")


    def populate_contacts(self):
        """
        Method to populate test data into contacts table.
        """
        logging.debug("Populating contacts data.")
        contacts = [
            {
                "user_id": self.listing_user_id,
                "phone_number": "111111111",
                "email_address": "test_listing@test.com"
            },
            {
                "user_id": self.booking_user_id,
                "phone_number": "222222222",
                "email_address": "test_booking@test.com"
            },
            {
                "user_id": self.access_user_id,
                "phone_number": "333333333",
                "email_address": "test_access@test.com"
            }
        ]
        try:
            response = self.client.table("contacts").upsert(contacts, on_conflict=["user_id"]).execute()
        except Exception as e:
            logging.error(f"Error populating contacts data: {e}")
            raise DataIsertException("Failed to populate contacts data.")
        logging.debug("Contacts data populated.")
    
    def populate_listing(self, place_id):
        """
        Method to populate a test listing.
        """
        logging.debug("Populating listing data.")
        listing = {
            "listing_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "user_id": self.listing_user_id,
            "place_id": place_id,
            "price_per_hour": 20.00,
            "charging_mode": "Mode 4",
            "charger_type": "Mennekes",
            "sustainable": True,
        }
        try:
            response = self.client.table("listings").upsert([listing]).execute()
        except Exception as e:
            logging.error(f"Error populating listing data: {e}")
            raise DataIsertException("Failed to populate listing data.")
        logging.debug("Listing data populated.")

    def populate_availability(self):
        """
        Method to populate availability data.
        """
        logging.debug("Populating availability data.")
        availability = {
            "listing_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "start_time": "2024-01-01 00:00:00+00",
            "end_time": "2024-01-01 04:00:00+00",
            "status": "available",
        }
        try:
            selected_availavility = self.client.table("availabilities").select("*").eq("listing_id", "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c").eq("start_time", "2024-01-01 00:00:00+00").single().execute()
        except Exception as e:
            if "contains 0 rows" in str(e):
                selected_availavility = None
        if selected_availavility is None:
            try:
                response = self.client.table("availabilities").insert(availability).execute()
                availability_id = response.data[0]["availability_id"]
            except Exception as e:
                logging.error(f"Error populating availability data: {e}")
                raise DataIsertException("Failed to populate availability data.")
        else:
            availability_id = selected_availavility.data["availability_id"]
        logging.debug("Availability data populated.")
        return availability_id

    def populate_booking_requests(self, availability_id):
        """
        Method to populate booking requests.
        """
        logging.debug("Populating booking requests data.")
        booking_request = {
            "availability_id": availability_id,
            "booking_user_id": self.booking_user_id,
            "status": "accepted",
        }
        try:
            selected_booking_request = self.client.table("booking_requests").select("*").eq("availability_id", availability_id).single().execute()
        except Exception as e:
            if "contains 0 rows" in str(e):
                selected_booking_request = None
        if selected_booking_request is None:
            try:
                response = self.client.table("booking_requests").insert([booking_request]).execute()
                request_id = response.data[0]["booking_request_id"]
            except Exception as e:
                logging.error(f"Error populating booking requests data: {e}")
                raise DataIsertException("Failed to populate booking requests data.")
        else:
            request_id = selected_booking_request.data["booking_request_id"]
        logging.debug("Booking requests data populated.")
        return request_id

    def populate_booking(self, availability_id, booking_request_id):
        """
        Method to populate booking.
        """
        logging.debug("Populating booking data.")
        booking = {
            "availability_id": availability_id,
            "booking_request_id": booking_request_id,
            "booking_user_id": self.booking_user_id,
        }
        try:
            selected_booking = self.client.table("bookings").select("*").eq("availability_id", availability_id).eq("booking_user_id", "5c81b17c-7e81-4eac-8ae2-f2da8af9a37a").single().execute()
        except Exception as e:
            if "contains 0 rows" in str(e):
                selected_booking = None
        if selected_booking is None:
            try:
                response = self.client.table("bookings").insert([booking]).execute()
                booking_id = response.data[0]["booking_id"]
            except Exception as e:
                logging.error(f"Error populating booking data: {e}")
                raise DataIsertException("Failed to populate booking data.")
        else:
            booking_id = selected_booking.data["booking_id"]
        logging.debug("Booking data populated.")
        return booking_id

    def populate_notification(self):
        """
        Method to populate a notification.
        """
        logging.debug("Populating notification data.")
        notification = {
            "notification_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "for_user_id": self.booking_user_id,
            "timestamp": "2024-01-01 00:00:00+00",
            "message": "Test notification",
            "date": "2024-01-01",
        }
        try:
            response = self.client.table("notifications").upsert([notification]).execute()
        except Exception as e:
            logging.error(f"Error populating notification data: {e}")
            raise DataIsertException("Failed to populate notification data.")
        logging.debug("Notification data populated.")

class SecurityTester():
    """
    Class to test the effectiveness of security policies.
    """

    def __init__(self):
        """
        Initialise from .env file.
        """
        logging.info("Initialising security tester.")
        load_dotenv(".env.local")
        load_dotenv(".env")
        supabase_anon_key = os.environ.get('PUBLIC_SUPABASE_ANON_KEY')
        supabase_access_user_key = os.environ.get('SUPABASE_ACCESS_USER_KEY')
        self.url = os.environ.get('PUBLIC_SUPABASE_URL')
        self.headers = {
            "accept": "application/vnd.pgrst.object+json",
            "accept-language": "en-US,en;q=0.9",
            "accept-profile": "public",
            "apikey": supabase_anon_key,
            "authorization": f"Bearer {supabase_access_user_key}",
            "cache-control": "no-cache",
            "pragma": "no-cache",
            "priority": "u=1, i",
            "sec-ch-ua": '"Chromium";v="127", "Not)A;Brand";v="99"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Linux"',
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "cross-site",
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
            "x-client-info": "supabase-ssr/0.4.0"
        }
        self.unauth_headers = {
            "accept": "application/vnd.pgrst.object+json",
            "accept-language": "en-US,en;q=0.9",
            "accept-profile": "public",
            "apikey": supabase_anon_key,
            "cache-control": "no-cache",
            "pragma": "no-cache",
            "priority": "u=1, i",
            "sec-ch-ua": '"Chromium";v="127", "Not)A;Brand";v="99"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Linux"',
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "cross-site",
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
            "x-client-info": "supabase-ssr/0.4.0"  
        }
        self.user_id = self.get_user_id(supabase_access_user_key)
        logging.info("Security tester initialised.")

    def get_user_id(self, token):
        """
        Method to get the user ID from the JWT.
        """
        logging.debug("Getting user ID.")
        try:
            decoded = jwt.decode(token, options={"verify_signature": False})
            return decoded["sub"]
        except Exception as e:
            logging.error(f"Error getting user ID: {e}")
            raise FailedTest("Failed to get user ID.")

    def run_tests(self):
        """
        Method to run all tests.
        """
        logging.info("Running security tests.")

        test_results = {
            "Policy prevents access places without authentication" : self.test_access_places_unauthenticated(),
            "Policy prevents write to another user's information" : self.test_write_non_self_user(),
            "Policy prevents read users without authentication" : self.test_read_users_unauthenticated(),
            "Policy prevents read contact information where user has not booked my listing": self.test_read_contact_where_user_has_booked_my_listing(),
            "Policy prevents read contact information where I have not booked user listing": self.test_read_contact_where_I_have_booked_user_listing(),
            "Policy prevents manage another user's contact information": self.test_manage_own_contact_information(),
            "Policy prevents read listings without authentication": self.test_read_listings_unauthenticated(),
            "Policy prevents manage another user's listing": self.test_manage_own_listing(),
            "Policy prevents read availability without authentication": self.read_availabiity_unauthenticated(),
            "Policy prevents manage another user's availability": self.manage_own_availability(),
            "Policy prevents manage booking requests I have not made": self.test_manage_booking_requests_i_made(),
            "Policy prevents manage booking requests for listings not owned by me": self.test_manage_booking_requests_for_my_listings(),
            "Policy prevents manage booking I have not made": self.test_manage_bookings_i_made(),
            "Policy prevents manage booking unrelated to my listings": self.test_manage_bookings_unrelated_to_me(),
            "Policy prevents access notifications unrelated to me": self.test_notifications_related_to_me(),
        }

        failed_tests = [k for k, v in test_results.items() if v == False]
        logging.info("Security tests complete.")
        logging.info(f"Failed tests: {len(failed_tests)} / {len(test_results)}")
        if len(failed_tests) > 0:
            for test in failed_tests:
                logging.error(f"Failed test: {test}")
            logging.info("Tests are intended to be run on a clean database and may produce unexpected failures if run on live data.") 

    def test_access_places_unauthenticated(self):
        """
        Test for policy:
            - Allow authenticated users to read/insert all places

        Test case:
            - Attempt to access places without authentication
        """
        logging.info("Testing access to places unauthenticated.")
        target = f"{self.url}/rest/v1/places"
        response = httpx.get(target, headers=self.unauth_headers)
        try:
            assert response.json()['message'] == "JSON object requested, multiple (or no) rows returned"
            assert response.json()['details'] == "The result contains 0 rows"
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_write_non_self_user(self):
        """
        Test for policy:
            - Allow me to manage my own user information 

        Test case:
            - Attempt to write to another user's information
        """
        logging.info("Testing write to another user's information.")
        target = f"{self.url}/rest/v1/users"
        data = {
            "user_id": "94ab65ce-8e09-4c22-a672-0e078221228e",
            "user_name": "Test Listing User",
            "home_place_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "work_place_id": None,
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_read_users_unauthenticated(self):
        """
        Test for policy:
            - Allow authenticated users to read all users

        Test case:
            - Attempt to read users without authentication
        """
        logging.info("Testing read users unauthenticated.")
        target = f"{self.url}/rest/v1/users"
        response = httpx.get(target, headers=self.unauth_headers)
        try:
            assert response.json()['message'] == "JSON object requested, multiple (or no) rows returned"
            assert response.json()['details'] == "The result contains 0 rows"
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_read_contact_where_user_has_booked_my_listing(self):
        """
        Test for policy:
            - Allow me to access the contact information of a user that has booked my listing 

        Test case:
            - Attempt to read contact information where user has not booked my listing
        """
        logging.info("Testing read contact where user has booked my listing.")
        target = f"{self.url}/rest/v1/contacts"
        response = httpx.get(target, headers=self.headers)
        try:
            assert type(response.json()) == dict
            assert response.json()['user_id'] == self.user_id
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_read_contact_where_I_have_booked_user_listing(self):
        """
        Test for policy:
            - Allow access to my contact information to a user whose listing I have booked 

        Test case:
            - Attempt to read contact information where I have not booked user listing
        """
        logging.info("Testing read contact where I have booked user listing.")
        target = f"{self.url}/rest/v1/contacts"
        response = httpx.get(target, headers=self.headers)
        try:
            assert type(response.json()) == dict
            assert response.json()['user_id'] == self.user_id
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_own_contact_information(self):
        """
        Test for policy:
            - Allow me to manage my own contact information 

        Test case:
            - Attempt to manage another user's contact information
        """
        logging.info("Testing manage own contact information.")
        target = f"{self.url}/rest/v1/contacts"
        data = {
            "user_id": "94ab65ce-8e09-4c22-a672-0e078221228e",
            "phone_number": "111111111",
            "email_address": "test"
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_read_listings_unauthenticated(self):
        """
        Test for policy:
            - Allow authenticated users to read all listings

        Test case:
            - Attempt to read listings without authentication
        """
        logging.info("Testing read listings unauthenticated.")
        target = f"{self.url}/rest/v1/listings"
        response = httpx.get(target, headers=self.unauth_headers)
        try:
            assert response.json()['message'] == "JSON object requested, multiple (or no) rows returned"
            assert response.json()['details'] == "The result contains 0 rows"
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_own_listing(self):
        """
        Test for policy:
            - Allow me to manage my own listing 

        Test case:
            - Attempt to manage another user's listing
        """
        logging.info("Testing manage own listing.")
        target = f"{self.url}/rest/v1/listings"
        data = {
            "listing_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "user_id": "94ab65ce-8e09-4c22-a672-0e078221228e",
            "place_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "price_per_hour": 20.00,
            "charging_mode": "Mode 4",
            "charger_type": "Mennekes",
            "sustainable": True,
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False
    
    def read_availabiity_unauthenticated(self):
        """
        Test for policy:
            - Allow authenticated users to read all availability

        Test case:
            - Attempt to read availability without authentication
        """
        logging.info("Testing read availability unauthenticated.")
        target = f"{self.url}/rest/v1/availabilities"
        response = httpx.get(target, headers=self.unauth_headers)
        try:
            assert response.json()['message'] == "JSON object requested, multiple (or no) rows returned"
            assert response.json()['details'] == "The result contains 0 rows"
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def manage_own_availability(self):
        """
        Test for policy:
            - Allow me to manage my own availability 

        Test case:
            - Attempt to manage another user's availability
        """
        logging.info("Testing manage own availability.")
        target = f"{self.url}/rest/v1/availabilities"
        data = {
            "listing_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "start_time": "2024-01-01 00:00:00+00",
            "end_time": "2024-01-01 04:00:00+00",
            "status": "available",
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_booking_requests_i_made(self):
        """
        Test for policy:
            - Allow me to manage booking requests I have made 

        Test case:
            - Attempt to manage booking requests I have not made
        """
        logging.info("Testing manage booking requests I made.")
        target = f"{self.url}/rest/v1/booking_requests"
        data = {
            "availability_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_user_id": "5c81b17c-7e81-4eac-8ae2-f2da8af9a37a",
            "status": "accepted",
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_booking_requests_for_my_listings(self):
        """
        Test for policy:
            - Allow me to manage booking requests for my listings 

        Test case:
            - Attempt to manage booking requests for listings not owned by me
        """
        logging.info("Testing manage booking requests for my listings.")
        target = f"{self.url}/rest/v1/booking_requests"
        data = {
            "availability_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_user_id": "5c81b17c-7e81-4eac-8ae2-f2da8af9a37a",
            "status": "accepted",
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_bookings_i_made(self):
        """
        Test for policy:
            - Allow me to manage booking I have made 

        Test case:
            - Attempt to manage booking I have not made
        """
        logging.info("Testing manage booking I made.")
        target = f"{self.url}/rest/v1/bookings"
        data = {
            "availability_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_request_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_user_id": "5c81b17c-7e81-4eac-8ae2-f2da8af9a37a",
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_manage_bookings_unrelated_to_me(self):
        """
        Test for policy:
            - Allow me to manage booking requests for my listings 

        Test case:
            - Attempt to manage booking unrelated to my listings
        """
        logging.info("Testing manage bookings unrelated to me.")
        target = f"{self.url}/rest/v1/bookings"
        data = {
            "availability_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_request_id": "d3a3b9e7-3a3a-4d4d-8e8e-3c3c3c3c3c3c",
            "booking_user_id": "5c81b17c-7e81-4eac-8ae2-f2da8af9a37a",
        }
        response = httpx.post(target, headers=self.headers, json=data)
        try:
            assert "new row violates row-level security policy for table" in response.json()['message'] 
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

    def test_notifications_related_to_me(self):
        """
        Test for policy:
            - Allow me to manage my own notifications 

        Test case:
            - Attempt to access notifications unrelated to me
        """
        logging.info("Testing notifications related to me.")
        target = f"{self.url}/rest/v1/notifications"
        response = httpx.get(target, headers=self.headers)
        try:
            assert response.json()['details'] == "The result contains 0 rows"
            logging.info("Test passed.")
            return True
        except:
            logging.error("Test failed.")
            return False

dp = DataPopulator()

availability_id, booking_request_id, booking_id = dp.populate_data()

st = SecurityTester()

st.run_tests()