import json
import logging
import sys
import time
import traceback

import requests

proxies = {
    "http": "",
    "https": "",
}

# The wait time from experience is between 60 to 600 seconds
default_wait_time_for_apache_wakeup = 15

class AviatrixException(Exception):
    def __init__(self, message="Aviatrix Error Message: ..."):
        super(AviatrixException, self).__init__(message)


# END class MyException


def function_handler(event):
    hostname = event["hostname"]
    aviatrix_api_version = event["aviatrix_api_version"]
    aviatrix_api_route = event["aviatrix_api_route"]
    old_admin_password = event["old_admin_password"]
    new_admin_password = event["new_admin_password"]
    aviatrix_customer_id = event["aviatrix_customer_id"]
    wait_time = default_wait_time_for_apache_wakeup

    # Reconstruct some parameters
    aviatrix_customer_id = aviatrix_customer_id.rstrip()
    aviatrix_customer_id = aviatrix_customer_id.lstrip()
    api_endpoint_url = (
        "https://" + hostname + "/" + aviatrix_api_version + "/" + aviatrix_api_route
    )

    # Step1. Wait until the rest API service of Aviatrix Controller is up and running
    logging.info(
        "START: Wait until API server of Aviatrix Controller is up and running"
    )

    wait_until_controller_api_server_is_ready(
        hostname=hostname,
        api_version=aviatrix_api_version,
        api_route=aviatrix_api_route,
        total_wait_time=wait_time,
        interval_wait_time=10,
    )
    logging.info("ENDED: Wait until API server of controller is up and running")

    # Step2. Login Aviatrix Controller as admin with old password
    logging.info("Start: Login in as admin with old password")
    response = login(
        api_endpoint_url=api_endpoint_url,
        username="admin",
        password=old_admin_password,
    )

    CID = response.json()["CID"]
    logging.info("End: Login as admin with old password")

    # Step3. Set Aviatrix Admin Password
    logging.info("START: Set Aviatrix Admin New Password by invoking Aviatrix API")
    response = set_aviatrix_admin_password(
        api_endpoint_url=api_endpoint_url,
        CID=CID,
        old_password=old_admin_password,
        new_password=new_admin_password
    )
    py_dict = response.json()
    logging.info("Aviatrix API response is : " + str(py_dict))
    logging.info("END: Set Aviatrix Admin New Password by invoking Aviatrix API")
    CID = None

    # Step4. Login Aviatrix Controller as admin with new password
    logging.info("Start: Login in as admin with new password")
    response = login(
        api_endpoint_url=api_endpoint_url,
        username="admin",
        password=new_admin_password,
    )

    CID = response.json()["CID"]
    logging.info("End: Login as admin with new password")

    # Step5. Set Aviatrix Customer ID
    # only BYOL license in Azure
    logging.info("START: Set Aviatrix Customer ID by invoking Aviatrix API")
    response = set_aviatrix_customer_id(
        api_endpoint_url=api_endpoint_url,
        CID=CID,
        customer_id=aviatrix_customer_id,
    )
    py_dict = response.json()
    logging.info("Aviatrix API response is : " + str(py_dict))
    logging.info("END: Set Aviatrix Customer ID by invoking aviatrix API")

def wait_until_controller_api_server_is_ready(
    hostname="123.123.123.123",
    api_version="v1",
    api_route="api",
    total_wait_time=300,
    interval_wait_time=10,
):
    payload = {"action": "login", "username": "test", "password": "test"}
    api_endpoint_url = "https://" + hostname + "/" + api_version + "/" + api_route

    # invoke the aviatrix api with a non-existed api
    # to resolve the issue where server status code is 200 but response message is "Valid action required: login"
    # which means backend is not ready yet
    payload = {"action": "login", "username": "test", "password": "test"}
    remaining_wait_time = total_wait_time

    """ Variable Description: (time_spent_for_requests_lib_timeout)
    Description:
        * This value represents how many seconds for "requests" lib to timeout by default.
    Detail:
        * The value 20 seconds is actually a rough number
        * If there is a connection error and causing timeout when
          invoking--> requests.get(xxx), it takes about 20 seconds for requests.get(xxx) to throw timeout exception.
        * When calculating the remaining wait time, this value is considered.
    """
    time_spent_for_requests_lib_timeout = 20
    last_err_msg = ""
    while remaining_wait_time > 0:
        try:
            # Reset the checking flags
            response_status_code = -1
            is_apache_returned_200 = False
            is_api_service_ready = False

            # invoke a dummy REST API to Aviatrix controller
            response = requests.post(url=api_endpoint_url, data=payload, verify=False, proxies=proxies)

            # check response
            # if the server is ready, the response code should be 200.
            # there are two cases that the response code is 200
            #   case1 : return value is false and the reason message is "Valid action required: login",
            #           which means the server is not ready yet
            #   case2 : return value is false and the reason message is "username ans password do not match",
            #           which means the server is ready
            if response is not None:
                response_status_code = response.status_code
                logging.info("Server status code is: %s", str(response_status_code))
                py_dict = response.json()
                if response.status_code == 200:
                    is_apache_returned_200 = True

                response_message = py_dict["reason"]
                response_msg_indicates_backend_not_ready = "Valid action required"
                response_msg_request_refused = "RequestRefused"
                # case1:
                if (
                    py_dict["return"] is False
                    and (response_msg_indicates_backend_not_ready in response_message
                    or response_msg_request_refused in response_message)
                ):
                    is_api_service_ready = False
                    logging.info(
                        "Server is not ready, and the response is :(%s)",
                        response_message,
                    )
                # case2:
                else:
                    is_api_service_ready = True
            # END outer if

            # if the response code is 200 and the server is ready
            if is_apache_returned_200 and is_api_service_ready:
                logging.info("Server is ready")
                return True
        except Exception as e:
            logging.exception(
                "Aviatrix Controller %s is not available", api_endpoint_url
            )
            last_err_msg = str(e)
            pass
            # END try-except

            # handle the response code is 404
            if response_status_code == 404:
                err_msg = (
                    "Error: Aviatrix Controller returns error code: 404 for "
                    + api_endpoint_url
                )
                raise AviatrixException(
                    message=err_msg,
                )
            # END if

        # if server response code is neither 200 nor 404, some other errors occurs
        # repeat the process till reaches case 2

        remaining_wait_time = (
            remaining_wait_time
            - interval_wait_time
            - time_spent_for_requests_lib_timeout
        )
        if remaining_wait_time > 0:
            time.sleep(interval_wait_time)
    # END while loop

    # if the server is still not ready after the default time
    # raise AviatrixException
    err_msg = (
        "Aviatrix Controller "
        + api_endpoint_url
        + " is not available after "
        + str(total_wait_time)
        + " seconds"
        + "Server status code is: "
        + str(response_status_code)
        + ". "
        + "The response message is: "
        + last_err_msg
    )
    raise AviatrixException(
        message=err_msg,
    )


# END wait_until_controller_api_server_is_ready()


def login(
    api_endpoint_url="https://123.123.123.123/v1/api",
    username="admin",
    password="********",
    hide_password=True,
):
    request_method = "POST"
    data = {"action": "login", "username": username, "password": password}
    logging.info("API endpoint url is : %s", api_endpoint_url)
    logging.info("Request method is : %s", request_method)

    # handle if the hide_password is selected
    if hide_password:
        payload_with_hidden_password = dict(data)
        payload_with_hidden_password["password"] = "************"
        logging.info(
            "Request payload: %s",
            str(json.dumps(obj=payload_with_hidden_password, indent=4)),
        )
    else:
        logging.info("Request payload: %s", str(json.dumps(obj=data, indent=4)))

    # send post request to the api endpoint
    response = send_aviatrix_api(
        api_endpoint_url=api_endpoint_url,
        request_method=request_method,
        payload=data,
    )
    return response


# End def login()


def send_aviatrix_api(
    api_endpoint_url="https://123.123.123.123/v1/api",
    request_method="POST",
    payload=dict(),
    retry_count=5,
    timeout=None,
):
    response = None
    responses = list()
    request_type = request_method.upper()
    response_status_code = -1

    for i in range(retry_count):
        try:
            if request_type == "GET":
                response = requests.get(
                    url=api_endpoint_url, params=payload, verify=False, proxies=proxies
                )
                response_status_code = response.status_code
            elif request_type == "POST":
                response = requests.post(
                    url=api_endpoint_url, data=payload, verify=False, proxies=proxies, timeout=timeout
                )
                response_status_code = response.status_code
            else:
                failure_reason = "ERROR : Bad HTTPS request type: " + request_type
                logging.error(failure_reason)
        except requests.exceptions.Timeout as e:
            logging.exception("WARNING: Request timeout...")
            responses.append(str(e))
        except requests.exceptions.ConnectionError as e:
            logging.exception("WARNING: Server is not responding...")
            responses.append(str(e))
        except Exception as e:
            traceback_msg = traceback.format_exc()
            logging.exception("HTTP request failed")
            responses.append(str(traceback_msg))
            # For error message/debugging purposes

        finally:
            if response_status_code == 200:
                return response
            elif response_status_code == 404:
                failure_reason = "ERROR: 404 Not Found"
                logging.error(failure_reason)

            # if the response code is neither 200 nor 404, repeat the precess (retry)
            # the default retry count is 5, the wait for each retry is i
            # i           =  0  1  2  3  4
            # wait time   =     1  2  4  8

            if i + 1 < retry_count:
                logging.info("START: retry")
                logging.info("i == %d", i)
                wait_time_before_retry = pow(2, i)
                logging.info("Wait for: %ds for the next retry", wait_time_before_retry)
                time.sleep(wait_time_before_retry)
                logging.info("ENDED: Wait until retry")
                # continue next iteration
            else:
                failure_reason = (
                    "ERROR: Failed to invoke Aviatrix API. Exceed the max retry times. "
                    + " All responses are listed as follows :  "
                    + str(responses)
                )
                raise AviatrixException(
                    message=failure_reason,
                )
            # END
    return response


# End def send_aviatrix_api()


def verify_aviatrix_api_response_login(response=None):
    # if successfully login
    # response_code == 200
    # api_return_boolean == true
    # response_message = "authorized successfully"

    py_dict = response.json()
    logging.info("Aviatrix API response is %s", str(py_dict))

    response_code = response.status_code
    if response_code != 200:
        err_msg = (
            "Fail to login Aviatrix Controller. The response code is" + response_code
        )
        raise AviatrixException(message=err_msg)

    api_return_boolean = py_dict["return"]
    if api_return_boolean is not True:
        err_msg = "Fail to Login Aviatrix Controller. The Response is" + str(py_dict)
        raise AviatrixException(
            message=err_msg,
        )

    api_return_msg = py_dict["results"]
    expected_string = "authorized successfully"
    if (expected_string in api_return_msg) is not True:
        err_msg = "Fail to Login Aviatrix Controller. The Response is" + str(py_dict)
        raise AviatrixException(
            message=err_msg,
        )


# End def verify_aviatrix_api_response_login()


def set_aviatrix_customer_id(
    api_endpoint_url="https://123.123.123.123/v1/api",
    CID="ABCD1234",
    customer_id="aviatrix-1234567.89",
):
    request_method = "POST"
    data = {"action": "setup_customer_id", "CID": CID, "customer_id": customer_id}

    logging.info("API endpoint url: %s", str(api_endpoint_url))
    logging.info("Request method is: %s", str(request_method))
    logging.info("Request payload is : %s", str(json.dumps(obj=data, indent=4)))

    response = send_aviatrix_api(
        api_endpoint_url=api_endpoint_url,
        request_method=request_method,
        payload=data,
    )
    return response


# End def set_aviatrix_customer_id()

def set_aviatrix_admin_password(
    api_endpoint_url="https://123.123.123.123/v1/api",
    CID="ABCD1234",
    #username="admin",
    old_password="password12345",
    new_password="newpassword12345"
):
    request_method = "POST"
    data = {"action": "edit_account_user", "what": "password", "username": "admin", "old_password": old_password, "new_password": new_password, "CID": CID}

    logging.info("API endpoint url: %s", str(api_endpoint_url))
    logging.info("Request method is: %s", str(request_method))
    logging.info("Request payload is : %s", str(json.dumps(obj=data, indent=4)))

    response = send_aviatrix_api(
        api_endpoint_url=api_endpoint_url,
        request_method=request_method,
        payload=data,
    )
    return response


# End def set_aviatrix_admin_password()

if __name__ == "__main__":
    logging.basicConfig(
        format="%(asctime)s aviatrix-azure-function--- %(message)s", level=logging.INFO
    )

    hostname = sys.argv[1]
    old_admin_password = sys.argv[2]
    new_admin_password = sys.argv[3]
    aviatrix_customer_id = sys.argv[4]

    event = {
        "hostname": hostname,
        "old_admin_password": old_admin_password,
        "new_admin_password": new_admin_password,
        "aviatrix_customer_id": aviatrix_customer_id,
        "aviatrix_api_version": "v1",
        "aviatrix_api_route": "api",
    }

    try:
        function_handler(event)
    except Exception as e:
        logging.exception("")
    else:
        logging.info("Aviatrix Controller has been initialized successfully")