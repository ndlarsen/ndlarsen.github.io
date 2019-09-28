function domOnLoadEventHandler(event) {
    const urlSearchParams = new URLSearchParams(window.location.search);
    const searchTerm = urlSearchParams.getAll("query").join(" ");

    if(searchTerm === null || searchTerm.trim() === ""){
        return;
    }

    var searchResult = index.search(searchTerm);

    if(searchResult.length === 0){
        noResultsFound();
    }
    else{
        displayResults(searchResult);
    }
}

function noResultsFound(){
    setTextAndDisplay("No results found.")
}

function displayResults(results){
    setTextAndDisplay("Results:")
    
    const h1 = document.getElementById("search-results-h");
    const ul = document.createElement("ul")

    if(h1 === null || h1 == undefined){
        throw new Error("Unable to locate element")
    }

    results.forEach(function(result){
        var item = store[result.ref];
        var li = document.createElement("li");
        var link = document.createElement("a");
        link.setAttribute("href", result.ref);
        link.innerHTML = item.title;
        li.appendChild(link);
        ul.appendChild(li);
    });

    h1.parentElement.appendChild(ul);
}

function setTextAndDisplay(text){
    if(typeof text !== "string"){
        throw new TypeError("Supplied argument is not a string");
    }
    const h = document.getElementById("search-results-h");

    if(h === null || h == undefined){
        throw new Error("Unable to locate element")
    }

    h.innerText = text;
    h.style.display = "block";
}
