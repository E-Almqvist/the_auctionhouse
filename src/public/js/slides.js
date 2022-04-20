let slideIdx = 0;
showSlides(slideIdx);

function nextSlide(offset) {
	showSlides(slideIdx += offset)
}

function currentSlide(i) {
	showSlides(slideIdx = i);
}

function showSlides(i) {
	let ii;
	let slides = document.getElementsByClassName("slide-container");
	let dots = document.getElementsByClassName("dot");

	console.log(slides);

	if( i > slides.length - 1 ) { slideIdx = 0; }
	if( i < 0 ) {slideIdx = slides.length - 1}

	for( ii = 0; ii < slides.length; ii++ ) {
		slides[ii].style.display = "none";
	}
	for( ii = 0; ii < dots.length; ii++ ) {
		dots[ii].className = dots[ii].className.replace(" active", "");
	}

	slides[slideIdx].style.display = "block";  
	dots[slideIdx].className += " active";
}
