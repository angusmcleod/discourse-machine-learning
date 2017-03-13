import computed from "ember-addons/ember-computed-decorators";
import UploadMixin from "discourse/mixins/upload";

export default Em.Component.extend(UploadMixin, {
  type: "txt",
  tagName: "span",

  validateUploadedFilesOptions() {
    return {};
  },

  @computed("uploading")
  uploadButtonText(uploading) {
    return uploading ? I18n.t("uploading") : this.get('uploadText');
  },

  @computed("uploading")
  uploadButtonDisabled(uploading) {
    // https://github.com/emberjs/ember.js/issues/10976#issuecomment-132417731
    return uploading ? true : null;
  },

  uploadDone(upload) {
    console.log(upload)
    this.sendAction("dataUploaded", upload);
  }
});
