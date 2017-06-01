module.exports = (Franz, options) => {
  let keychain = '';
  let timer = false;
  let goToByName = function(name) {
    let list = document.getElementById('project_list').querySelectorAll('.name span')
    list.forEach(function(el) {
      if (el.innerText === name) {
        el.parentElement.parentElement.parentElement.parentElement.parentElement.click()
      }
    })
  }
  let scrollAnimation = function(pix) {
      let mod = pix > 0 ? 1 : -1
      let i = Math.abs(pix)
      let int = setInterval(function() {
        scrollBy(0, mod)
        if (i-- < 0) {
          clearInterval(int)
        }
      },1)

  }
  let keymap = {
    'gi': function() {
      document.getElementById('filter_inbox').click()
    },
    'gt': function() {
      document.getElementById('filter_inbox').nextSibling.nextSibling.click()
    },
    'gu': function() {
      goToByName('UKPOS')
    },
    'gp': function() {
      goToByName('Personal')
    },
    'gw': function() {
      goToByName('Work')
    },
    'j': function() {
      scrollAnimation(40)
    },
    'k': function() {
      scrollAnimation(-40)
    },
    'gg': function() {
      window.scrollTo(0, 0)
    },
    'G': function() {
      window.scrollTo(0, 9999999)
    }
  }


  document.addEventListener('keypress', function(ev) {
    if (
      document.activeElement.classList.contains('richtext_editor') ||
      document.activeElement.tagName === 'INPUT' ||
      document.activeElement.tagName === 'TEXTAREA' ||
      document.activeElement.tagName === 'SELECT'
    ) {
      return;
    }

    clearTimeout(timer)

    if (keychain.length) {
      ev.preventDefault()
    }

    keychain += ev.key

    timer = setTimeout(function() {
      keychain = ''
    }, 300)

    if (keymap[keychain]) {
      keymap[keychain]()
      keychain = ''
    }
  })
}
