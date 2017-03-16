import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

const Input = Discourse.Model.extend();

Input.reopenClass({
  list() {
    return ajax('/admin/ml/inputs.json').then((result) => {
      let inputs = [];
      result.forEach((i) => {
        inputs.push(Input.create(i));
      });
      return inputs;
    })
  }
});

export default Input;
