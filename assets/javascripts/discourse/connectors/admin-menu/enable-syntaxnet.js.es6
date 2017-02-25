import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default {
  actions: {
    buildImage() {
     ajax("/ml/build-image", {
       type: 'POST',
       data: {
         name: 'tf',
       }
     }).then(function (result, error) {
       if (error) {
         popupAjaxError(error);
       }
     });
    }
  }
}
