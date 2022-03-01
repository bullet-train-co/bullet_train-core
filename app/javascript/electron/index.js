document.addEventListener("turbo:load", () => {
  if (navigator.userAgent.toLocaleLowerCase().includes('electron')) {
    document.body.classList.add('electron')
  }
})