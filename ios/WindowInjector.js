window.fetchFallback = window.fetch;
window.fetch = async (...args) => {
    const url = args[0].url;
    const result = await window.fetchFallback(...args);

    if(url.startsWith('https://www.youtube.com/youtubei/v1/live_chat/get_live_chat')) {
        const response = await (await result.clone()).json();
        try {
            window.dispatchEvent(new CustomEvent('messageReceive', { detail: response }));
        } catch(e) { console.log(e); }
    }
    return result;
}

async function switchChat() {
    let count = 2;
    document.querySelectorAll('.yt-dropdown-menu').forEach((e) => {
        if (/Live chat/.exec(e.innerText) && count > 0) {
            e.click();
            count--;
        }
    });
}

const isReplay = window.location.href.startsWith(
    'https://www.youtube.com/live_chat_replay'
);

const formatTimestamp = (timestamp) => {
    return (new Date(parseInt(timestamp) / 1000)).toLocaleTimeString(navigator.language,
        { hour: '2-digit', minute: '2-digit' });
};

const getMillis = (timestamp, usec) => {
    let secs = Array.from(timestamp.split(':'), t => parseInt(t)).reverse();
    secs = secs[0] + (secs[1] ? secs[1] * 60 : 0) + (secs[2] ? secs[2] * 60 * 60 : 0);
    secs *= 1000;
    secs += usec % 1000;
    secs /= 1000;
    return secs;
};

const colorConversionTable = {
    4280191205: 'blue',
    4278248959: 'lightblue',
    4280150454: 'turquoise',
    4294953512: 'yellow',
    4294278144: 'orange',
    4293467747: 'pink',
    4293271831: 'red'
};

const messageReceiveCallback = async(response) => {
    try {
        const messages = [];
        if (!response.continuationContents) {
            console.debug('Response was invalid', response);
            return;
        }
        console.log("Hello world");
        
        (
            response.continuationContents.liveChatContinuation.actions || []
        ).forEach((action, i) => {
            try {
                let currentElement = action.addChatItemAction;
                const offsetMs = response.continuationContents?.liveChatContinuation.continuations[0].timedContinuationData?.timeoutMs || response.continuationContents?.liveChatContinuation.continuations[0].invalidationContinuationData?.timeoutMs;
                
                if (action.replayChatItemAction != null) {
                    const thisAction = action.replayChatItemAction.actions[0];
                    currentElement = thisAction.addChatItemAction;
                    offsetMs = action.replayChatItemAction.videoOffsetTimeMsec;
                }
                currentElement = (currentElement || {}).item;
                if (!currentElement) {
                    return;
                }
                const messageItem = currentElement.liveChatTextMessageRenderer ||
                    currentElement.liveChatPaidMessageRenderer ||
                    currentElement.liveChatPaidStickerRenderer;
                if (!messageItem) {
                    return;
                }
                if (!messageItem.authorName) {
                    console.log(currentElement);
                    return;
                }
                messageItem.authorBadges = messageItem.authorBadges || [];
                const authorTypes = [];
                const authorTypesThumbnails = [];
                messageItem.authorBadges.forEach((badge) => {
                    const thumbnails = badge.liveChatAuthorBadgeRenderer.customThumbnail.thumbnails;
                    authorTypes.push(badge.liveChatAuthorBadgeRenderer.tooltip.toLowerCase())
                    authorTypesThumbnails.push(thumbnails[thumbnails.length - 1].url)
                });
                const runs = [];
                if (messageItem.message) {
                    messageItem.message.runs.forEach((run) => {
                        if (run.text) {
                            runs.push({
                                type: 'text',
                                text: decodeURIComponent(escape(unescape(encodeURIComponent(
                                    run.text
                                ))))
                            });
                        } else if (run.emoji) {
                            runs.push({
                                type: 'emote',
                                src: run.emoji.image.thumbnails[0].url,
                                emojiId: run.emoji.emojiId
                            });
                        }
                    });
                }
                const timestampUsec = parseInt(messageItem.timestampUsec);
                const timestampText = (messageItem.timestampText || {}).simpleText;
                const date = new Date();
                const item = {
                    author: {
                        name: messageItem.authorName.simpleText,
                        id: messageItem.authorExternalChannelId,
                        types: authorTypes,
                        thumbnails: authorTypesThumbnails
                    },
                    index: i,
                    messages: runs,
                    timestamp: Math.round(parseInt(timestampUsec) / 1000),
                    showtime: isReplay ? offsetMs : (timestampUsec / 1000) + offsetMs + 2000
                };
                if (currentElement.liveChatPaidMessageRenderer) {
                    item.superchat = {
                        amount: messageItem.purchaseAmountText.simpleText,
                        color: colorConversionTable[messageItem.bodyBackgroundColor]
                    };
                }
                messages.push(item);
            } catch (e) {
                console.debug('Error while parsing message.', { e });
            }
        });
        const chunk = {
            type: 'messageChunk',
            messages: messages,
            isReplay
        };

        window.dispatchEvent(new CustomEvent('messagePostProcess', { detail: JSON.stringify(chunk) }));
    } catch (e) {
        console.debug(e);
    }
};

for (event_name of ['visibilitychange', 'webkitvisibilitychange', 'blur']) {
    window.addEventListener(event_name, e => e.stopImmediatePropagation(), true);
}

window.addEventListener('messageReceive', d => messageReceiveCallback(d.detail));
window.addEventListener('messagePostProcess', d => window.webkit.messageHandlers.ios_messageReceive.postMessage(d.detail))
document.querySelector('#chat>#item-list').remove();

switchChat().then(() => console.log('Chat switched to all chat'));
