const collapseMenu = (burger, menu) => {
	if (burger.classList.contains('is-active') && menu.classList.contains('is-active')) {
		burger.classList.remove('is-active');
		menu.classList.remove('is-active');
	}
};

document.addEventListener('DOMContentLoaded', () => {
	const scrollNavs = document.getElementsByClassName('navbar-scroll');
	const navbarBurger = document.querySelector('.navbar-burger');
	const navbarMenu = document.querySelector('.navbar-menu');

	// removes the class is-active on initial load because is-active is active by default
	// for users that has JavaScript turned off
	collapseMenu(navbarBurger, navbarMenu);

	navbarBurger.addEventListener('click', () => {
		navbarBurger.classList.toggle('is-active');
		navbarMenu.classList.toggle('is-active');
	});

	Array.from(scrollNavs).forEach(navLink => {
		navLink.addEventListener('click', e => {
			e.preventDefault();

			const hrefId = navLink.getAttribute('href').substring(1);
			const targetSection = document.getElementById(hrefId);

			collapseMenu(navbarBurger, navbarMenu);

			targetSection.scrollIntoView({behavior: "smooth"});
		});
	});
});
