export function getContiguousRequests(calendarData) {
    let requestBlocks = {};
    calendarData.forEach((day) => {
        day.forEach((segment) => {
            if (segment.state === "requested") {
                segment.objects.forEach((object) => {
                    if (object.booking_requests.length > 0) {
                        object.booking_requests.forEach((request) => {
                            const userId = request.booking_user_id;
                            const startTime = object.start_time;
                            const endTime = object.end_time;
                            const requestId = request.booking_request_id;
                            const availabilityId = object.availability_id;
                            if (!requestBlocks[userId]) {
                                requestBlocks[userId] = [];
                            }

                            const userBlocks = requestBlocks[userId];
                            const lastBlock =
                                userBlocks[userBlocks.length - 1];

                            if (lastBlock && lastBlock.end === startTime) {
                                lastBlock.end = endTime;
                                lastBlock.requestIds.push(requestId);
                                lastBlock.availabilityIds.push(
                                    availabilityId,
                                );
                            } else {
                                userBlocks.push({
                                    start: startTime,
                                    end: endTime,
                                    requestIds: [requestId],
                                    availabilityIds: [availabilityId],
                                });
                            }
                        });
                    }
                });
            }
        });
    });
    return requestBlocks;
}

export function getContiguousBookings(calendarData) {
    let bookingBlocks = {};
    calendarData.forEach((day) => {
        day.forEach((segment) => {
            if (segment.state === "booked") {
                segment.objects.forEach((object) => {
                    if (object.bookings) {
                        const userId = object.bookings.booking_user_id;
                        const startTime = object.start_time;
                        const endTime = object.end_time;
                        const bookingId = object.bookings.booking_id;
                        const availabilityId = object.availability_id;
                        if (!bookingBlocks[userId]) {
                            bookingBlocks[userId] = [];
                        }

                        const userBlocks = bookingBlocks[userId];
                        const lastBlock = userBlocks[userBlocks.length - 1];

                        if (lastBlock && lastBlock.end === startTime) {
                            lastBlock.end = endTime;
                            lastBlock.bookingIds.push(bookingId);
                            lastBlock.availabilityIds.push(availabilityId);
                        } else {
                            userBlocks.push({
                                start: startTime,
                                end: endTime,
                                bookingIds: [bookingId],
                                availabilityIds: [availabilityId],
                            });
                        }
                    }
                });
            }
        });
    });
    return bookingBlocks;
}

export function isWithinWindow(startTime, endTime, checkTime) {
    const start = new Date(startTime).getTime();
    const end = new Date(endTime).getTime();
    const check = new Date(checkTime).getTime();
    return check >= start && check < end;
}

export function prettifyDate(date) {
    return new Date(date).toLocaleString();
}

export function getStartEndDate(selectedDate) {
    let dateWindow = Array.from({ length: 7 }, (_, i) => {
        let date = new Date(selectedDate);
        date.setDate(date.getDate() + i - date.getDay());
        return date;
    });
    let startDate = dateWindow[0].toISOString().split("T")[0] + "T00:00:00+10";
    let endDate = dateWindow[6].toISOString().split("T")[0] + "T23:59:59+10";
    return { startDate, endDate };
}