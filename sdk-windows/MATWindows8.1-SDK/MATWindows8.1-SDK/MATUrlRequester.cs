using Newtonsoft.Json.Linq;
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;

namespace MobileAppTracking
{
    class MATUrlRequester
    {
        private const string SETTINGS_MATEVENTQUEUE_KEY = "mat_event_queue";
        private const int MAX_NUMBER_OF_RETRY_ATTEMPTS = 5;

        Parameters parameters;
        MATEventQueue eventQueue;
        string currentUrl;
        int currentUrlAttempt;

        internal MATUrlRequester(Parameters parameters, MATEventQueue eventQueue) 
        {
            this.parameters = parameters;
            this.eventQueue = eventQueue;
        }

        internal void SendRequest(string urlInfo, int urlAttempt)
        {
            this.currentUrl = urlInfo;
            this.currentUrlAttempt = urlAttempt;
            string url = urlInfo + "&sdk_retry_attempt=" + urlAttempt;

            HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(url); 
            request.BeginGetResponse(GetUrlCallback, request);
        }

        private void GetUrlCallback(IAsyncResult result)
        {
            HttpWebRequest request = result.AsyncState as HttpWebRequest;
            try
            {
                HttpWebResponse response = (HttpWebResponse)request.EndGetResponse(result);

                using (Stream stream = response.GetResponseStream())
                {
                    StreamReader reader = new StreamReader(stream, Encoding.UTF8);
                    string responseString = reader.ReadToEnd();
                    HttpStatusCode statusCode = response.StatusCode;

                    // If status between 200 and 300, success
                    if (statusCode >= HttpStatusCode.OK && statusCode < HttpStatusCode.MultipleChoices)
                    {
                        JToken root = JObject.Parse(responseString);

                        JToken successToken = root["success"];
                        bool success = successToken.ToString().ToLower().Equals("true");

                        if (success)
                        {
                            if (parameters.matResponse != null)
                                parameters.matResponse.DidSucceedWithData(responseString);

                            // Get site_event_type from json response
                            JToken siteEventTypeToken = root["site_event_type"];
                            string siteEventType = siteEventTypeToken.ToString();

                            // Only store log_id for opens
                            if (siteEventType.Equals("open"))
                            {
                                JToken logIdToken = root["log_id"];
                                string logId = logIdToken.ToString();

                                if (parameters.OpenLogId == null)
                                    parameters.OpenLogId = logId;
                                parameters.LastOpenLogId = logId;
                            }
                        }
                        else
                        {
                            if (parameters.matResponse != null)
                                parameters.matResponse.DidFailWithError(responseString);
                            if (currentUrlAttempt < MAX_NUMBER_OF_RETRY_ATTEMPTS)
                            {
                                Debug.WriteLine("MAT request failed, will be queued");
                                eventQueue.AddToQueue(currentUrl, ++currentUrlAttempt);
                            }
                            else
                            {
                                Debug.WriteLine("Exceeded maximum number of retries. Will not be requeued.");
                            }
                        }

                        if (parameters.DebugMode)
                            Debug.WriteLine("Server response is " + responseString);
                    }
                    else // Requeue all other requests
                    {
                        if (currentUrlAttempt < MAX_NUMBER_OF_RETRY_ATTEMPTS)
                        {
                            Debug.WriteLine("MAT request failed, will be queued");
                            eventQueue.AddToQueue(currentUrl, ++currentUrlAttempt);
                        }
                        else
                        {
                            Debug.WriteLine("Exceeded maximum number of retries. Will not be requeued.");
                        }
                    }
                }
            }
            catch (WebException e)
            {
                Debug.WriteLine(e.Message);
                // Requeue the request for SSL error
                // Have to convert to String because TrustFailure isn't accessible in this .NET WebExceptionStatus for some reason
                if (e.Status.ToString().Equals("TrustFailure"))
                {
                    if (currentUrlAttempt < MAX_NUMBER_OF_RETRY_ATTEMPTS)
                    {
                        Debug.WriteLine("SSL error, will be queued");
                        eventQueue.AddToQueue(currentUrl, ++currentUrlAttempt);
                    }
                    else
                    {
                        Debug.WriteLine("Exceeded maximum number of retries. Will not be requeued.");
                    }
                    return;
                }

                //For 400 (HttpWebRequest throws WebException on 4XX-5XX, so the logic must be written here)
                //We may want to switch to HttpClient for Windows Phone 8, but this requires downloading a separate library (still in beta, last I checked).
                //Within WebException is the only way to provide feedback to the client.
                if (e.Response != null)
                {
                    using (WebResponse webResponse = e.Response)
                    {
                        HttpWebResponse httpWebResponse = (HttpWebResponse)webResponse;
                        using (Stream stream = webResponse.GetResponseStream())
                        using (StreamReader streamReader = new StreamReader(stream, Encoding.UTF8))
                        {
                            string responseString = streamReader.ReadToEnd();
                            if (httpWebResponse.StatusCode == HttpStatusCode.BadRequest && webResponse.Headers["X-MAT-Responder"] != null)
                            {
                                if (parameters.matResponse != null)
                                    parameters.matResponse.DidFailWithError((responseString));
                                Debug.WriteLine("MAT request received 400 error from server, won't be retried");
                            }
                            else //Requeue for any other status code 
                            {
                                if (parameters.matResponse != null)
                                    parameters.matResponse.DidFailWithError((responseString));
                                if (currentUrlAttempt < MAX_NUMBER_OF_RETRY_ATTEMPTS)
                                {
                                    Debug.WriteLine("MAT request failed, will be queued");
                                    eventQueue.AddToQueue(currentUrl, ++currentUrlAttempt);
                                }
                                else
                                {
                                    Debug.WriteLine("Exceeded maximum number of retries. Will not be requeued.");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
