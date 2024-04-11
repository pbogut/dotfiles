module.exports = (config, Ferdi) => {
  setInterval(() => {
    let messages = document.getElementsByClassName('_unreadBadge')

    if (messages.length > 0) {
      for (let i = 0; i< messages.length; i++) {
        let count = messages[i].innerText;
        let name = messages[i].parentElement.parentElement.innerText
            .replace(/\d+$/, '')
            .replace(/\n/g, '');

        if (count && parseInt(count) > 0) {
          new Notification(name + ' - Chatwork Message!', {
            body: 'You have unread message from ' + name + ' (' + count + ')',
            tag: 'importantMessage' + name,
            icon: 'https://s3.amazonaws.com/ec-commonassets/site/chatwork/blog/official/icon_facebook_thumbnail.png'
          });
        }
      }
    }

  }, 10000) // every 10 secs (as notification is displayes for 10 sec)

  const getMessages = () => {
    let messages = document.getElementsByClassName('_unreadBadge')
    let allCount = 0;

    if (messages.length > 0) {
      for (let i = 0; i< messages.length; i++) {
        let count = messages[i].innerText;
        if (count && parseInt(count) > 0) {
          allCount += count;
        }
      }
    }

    Ferdi.setBadge(messages.length, allCount);
  }
  Ferdi.loop(getMessages);
}
