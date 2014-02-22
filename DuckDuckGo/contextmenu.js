var ddg_injected = true;

var ddg_imageURL = '';

function ddg_findElementAtPoint(x, y) {
    ddg_imageURL = '';

    var node = document.elementFromPoint(x, y);
    while (node) {
        if (node.tagName) {
            if (node.tagName.toLowerCase() == 'img' && node.src && node.src.length > 0) {
                ddg_imageURL = node.src;
                break;
            }
        }
        node = node.parentNode;
    }
}