const collapseMenu = (burger, menu) => {
	if (burger.classList.contains('is-active') && menu.classList.contains('is-active')) {
		burger.classList.remove('is-active');
		menu.classList.remove('is-active');
	}
};

// credit to: https://stackoverflow.com/a/5298684
const removeHash = () => {
	var scrollV, scrollH, loc = window.location;
	if ("pushState" in history) {
		history.pushState("", document.title, loc.pathname + loc.search);
	} else {
		// Prevent scrolling by storing the page's current scroll offset
		scrollV = document.body.scrollTop;
		scrollH = document.body.scrollLeft;

		loc.hash = "";

		// Restore the scroll offset, should be flicker free
		document.body.scrollTop = scrollV;
		document.body.scrollLeft = scrollH;
	}
}

document.addEventListener('DOMContentLoaded', () => {
	const scrollNavs = document.getElementsByClassName('navbar-scroll');
	const navbarBurger = document.querySelector('.navbar-burger');
	const navbarMenu = document.querySelector('.navbar-menu');

	// removes the class is-active on initial load because is-active is active by default
	// for users that has JavaScript turned off
	collapseMenu(navbarBurger, navbarMenu);

	if (window.location.hash.length > 0) {
		const target = document.getElementById(window.location.hash.substring(1));

		removeHash();

		if (target != null) {
			target.scrollIntoView({behavior: "smooth"});
		}
	}

	navbarBurger.addEventListener('click', () => {
		navbarBurger.classList.toggle('is-active');
		navbarMenu.classList.toggle('is-active');
	});

	Array.from(scrollNavs).forEach(navLink => {
		navLink.addEventListener('click', e => {
			e.preventDefault();

			collapseMenu(navbarBurger, navbarMenu);

			let hrefId = navLink.getAttribute("href");

			if (window.location.pathname == "/") {
				if (window.location.hash.length > 0) {
				}

				if (hrefId.length > 0 && hrefId.startsWith("#")) {
					hrefId = hrefId.substring(1);
				} else if (hrefId == "/") {
					hrefId = "home";
				}

				const targetSection = document.getElementById(hrefId);

				targetSection.scrollIntoView({behavior: "smooth"});
			} else {
				let newHref = window.location.origin;

				if (hrefId != "/") {
					newHref += hrefId;
				}

				window.location.href = newHref;
			}
		});
	});
});
