function createCalendar(parentElement, year, month, onDateCreated) {

    // Get the first and last date of the selected month

    let dateFirst = new Date(year, month, 1);
    let dateLast = new Date(year, month + 1, 0);

    // Generate the basic table elements

    let table = document.createElement("table");

    let thead = document.createElement("thead");
    let tbody = document.createElement("tbody");

    table.appendChild(thead);
    table.appendChild(tbody);

    // Generate the month thead row

    let prevMonth = new Date(year, month - 1, 1);
    let nextMonth = new Date(year, month + 1, 1);

    let monthRow = document.createElement("tr");
    let monthCell = document.createElement("th");
    monthCell.setAttribute("colspan", "7");
    monthCell.appendChild(document.createTextNode(`${dateFirst.toLocaleString("en-us", { month: "long" })} ${year}`));
    let prev = document.createElement("span");
    prev.setAttribute("id", "btnPrev");
    //prev.textContent = "Prev";
    prev.textContent = prevMonth.toLocaleString("en-us", { month: "short" });
    let next = document.createElement("span");
    next.setAttribute("id", "btnNext");
    //next.textContent = "Next";
    next.textContent = nextMonth.toLocaleString("en-us", { month: "short" });
    monthCell.appendChild(prev);
    monthCell.appendChild(next);
    monthRow.appendChild(monthCell);

    thead.appendChild(monthRow);

    // Generate the Sunday - Saturday thead row

    let days = document.createElement("tr");

    addDay(days, "Sunday");
    addDay(days, "Monday");
    addDay(days, "Tuesday");
    addDay(days, "Wednesday");
    addDay(days, "Thursday");
    addDay(days, "Friday");
    addDay(days, "Saturday");

    thead.appendChild(days);

    // Helper function for the Sunday - Saturday thead row generation

    function addDay(parent, day) {
        let element = document.createElement("th");
        let text = document.createTextNode(day);
        element.appendChild(text);
        parent.appendChild(element);
    }

    // TBODY

    let dates = [];

    // The first date of the month can start on any day of the week.  The table needs to
    // be padded to properly align the dates with the correct day of the week.  By using
    // negative dates it is easy to include the dates from the previous month the calendar.

    for (let i = dateFirst.getDay(); i > 0; i--) {
        dates.push(-1 * (i - 1));
    }

    // Churn through the dates of the month and add them to the dates array.  Once the dates
    // array contains 7 dates add the week to the calendar and reset the dates array.

    for (let i = 1; i <= dateLast.getDate(); i++) {
        dates.push(i);
        if (dates.length == 7) {
            addWeek(tbody, dates);
            dates = [];
        }
    }

    // The last date of the month can fall on any day of the week.  The rest of the week is filled
    // in with the dates from the coming month.

    if (dates.length > 0) {
        let i = dateLast.getDate();
        while (dates.length < 7) {
            dates.push(++i);
        }
        addWeek(tbody, dates);
    }

    // Helper function to add a week (row) to the calendar (table)

    function addWeek(parent, dates) {
        let row = document.createElement("tr");
        for (let date of dates) {
            addDate(row, date);
        }
        parent.appendChild(row);
    }

    // Helper function to add a date (cell) to the week (row)

    function addDate(parent, date) {
        let cell = document.createElement("td");
        if (date <= 0 || date > dateLast.getDate()) {
            cell.setAttribute("class", "inactive");
        }
        if (onDateCreated) {
            onDateCreated(cell, new Date(year, month, date));
        }
        parent.appendChild(cell);
    }

    // Add the calendar to the document

    parentElement.appendChild(table);
}
