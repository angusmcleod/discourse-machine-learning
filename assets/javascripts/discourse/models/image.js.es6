import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

const Image = Discourse.Model.extend({
  build() {
    ajax("images/build", { type: 'POST', data: {
       name: this.get('name')
     }
    }).then(function (result, error) {
     if (error) {
       popupAjaxError(error);
     }
    });
  },

  remove() {
    const name = this.get('name');
    ajax("images/remove", { type: 'POST', data: {
       name: name
     }
   }).then(function (result, error) {
     if (error) {
        popupAjaxError(error);
     }
    });
  }
});

Image.reopenClass({
  list() {
    return ajax('/admin/ml/images.json').then((result) => {
      let images = [];
      result.forEach((i) => {
        images.push(Image.create(i));
      });
      return images;
    })
  }
});

export default Image;
