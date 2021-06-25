document.addEventListener('DOMContentLoaded', () => {
	const scrollNavs = document.getElementsByClassName('navbar-scroll');
	const navbarBurger = document.querySelector('.navbar-burger');
	const navbarMenu = document.querySelector('.navbar-menu');

	// removes the class is-active on initial load because is-active is active by default
	// for users that has JavaScript turned off
	if (navbarBurger.classList.contains('is-active') && navbarMenu.classList.contains('is-active')) {
		navbarBurger.classList.remove('is-active');
		navbarMenu.classList.remove('is-active');
	}

	navbarBurger.addEventListener('click', () => {
		navbarBurger.classList.toggle('is-active');
		navbarMenu.classList.toggle('is-active');
	});

	Array.from(scrollNavs).forEach(navLink => {
		navLink.addEventListener('click', e => {
			e.preventDefault();

			const hrefId = navLink.getAttribute('href').substring(1);
			const targetSection = document.getElementById(hrefId);

			targetSection.scrollIntoView({behavior: "smooth"});
		});
	});
});
