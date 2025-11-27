# Carbon Intensity Dashboard

An iOS Flutter application that displays the current UK carbon intensity and a half-hourly intensity graph for the day, using NESO's Carbon Intensity API (https://carbon-intensity.github.io/api-definitions/#carbon-intensity-api-v2-0-0).

## How it Works

1. **Current Carbon Intensity**

- Fetches national carbon intensity from current half-hour
- Background colour changes based on carbon intensity index (e.g. very low, low, moderate, high, very high)

2. **Half-Hourly Intensity Graph**

- Fetches today's carbon intensities from every half-hour
- Used fl_chart package (https://pub.dev/packages/fl_chart)
- Solid white line: Actual intensity values
- Dashed grey line: Forecast values
- Touch tooltips show timestamp and corresponding intensity value

3. **Error Handling**

- App bar shows: Last updated time + no internet connection/API unavailable
- Used internet_connection_checker_plus package (https://pub.dev/packages/internet_connection_checker_plus) for internet errors
- Forecast value is used when actual is unavailable

4. **Loading states**

- Used CircularProgressIndicator for when data is loading

5. **Auto-refresh**

- Refreshes every 30 minutes to match API's frequency

## Assumptions

- API updates at consistent 30 minute intervals
- Actual intensity is 0 when unavailable, so forecast values should be used in place
- App is to be used only in the UK
- App is to be used on iOS devices

## Future Improvements & Additions

- Add an info button could open a pop-up that shows a brief overview of the dashboard, including the meaning of background colours in the current intensity widget and actual vs forecast line key in the graph
- Additional themes could be added for better user experience
- Improved graph UX with zoom options, animated line transitions and better tooltip text
- Fix visual gap in graph between actual and forecast lines on the graph
- More error states for different cases
- Manual refresh button (just in case)
