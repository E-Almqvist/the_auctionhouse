window.onscroll = function() {toggleStickyHeader()};

var header = document.querySelector("header");
var sticky = header.offsetTop;

function toggleStickyHeader() {
	if (window.pageYOffset > sticky) {
		header.classList.add("sticky");
	} else {
		header.classList.remove("sticky");
	}
} 
