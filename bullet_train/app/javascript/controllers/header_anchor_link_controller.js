import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("****************************** from header anchor link controller")
    const headers = this.element.querySelectorAll('h2, h3, h4, h5, h6')

    headers.forEach((header) => {
      const headerText = header.textContent.trim()
      const anchorName = headerText.toLowerCase().replace(/\s+/g, '_')

      const anchorTag = document.createElement('a')
      anchorTag.name = anchorName

      const linkTag = document.createElement('a')
      linkTag.href = `#${anchorName}`
      linkTag.textContent = '#'

      const linkContainer = document.createElement('span')
      linkContainer.appendChild(document.createTextNode(' '))
      linkContainer.appendChild(anchorTag)
      linkContainer.appendChild(document.createTextNode(' '))
      linkContainer.appendChild(linkTag)

      header.appendChild(linkContainer)
    });
  }
}