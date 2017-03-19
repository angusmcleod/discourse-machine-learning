import codecs
import os.path
import numpy as np
import re
import itertools
from collections import Counter

PAD_MARK = "<PAD/>"
UNK_MARK = "<UNK/>"

def clean_str(string):
    """
    Tokenization/string cleaning for all datasets except for SST.
    Original taken from https://github.com/yoonkim/CNN_sentence/blob/master/process_data.py
    """
#    string = re.sub(r"[^A-Za-z0-9(),!?\'\`]", " ", string)  # blocked to allow non-english char-set
    string = re.sub(r"\'s", " \'s", string)
    string = re.sub(r"\'ve", " \'ve", string)
    string = re.sub(r"n\'t", " n\'t", string)
    string = re.sub(r"\'re", " \'re", string)
    string = re.sub(r"\'d", " \'d", string)
    string = re.sub(r"\'ll", " \'ll", string)
    string = re.sub(r",", " , ", string)
    string = re.sub(r"!", " ! ", string)
    string = re.sub(r"\(", " \( ", string)
    string = re.sub(r"\)", " \) ", string)
    string = re.sub(r"\?", " \? ", string)
    string = re.sub(r"\s{2,}", " ", string)
    return string.strip().lower()


def pad_sentences(sentences, max_sent_len_path):
    """
    Pads all sentences to the same length. The length is defined by the longest sentence.
    Returns padded sentences.
    """
    max_sequence_length = 0
    # Load base max sent length
    if len(max_sent_len_path) > 0 :
        max_sequence_length = int( open( max_sent_len_path, 'r' ).readlines()[0] )
    else :
        max_sequence_length = max(len(x) for x in sentences)
    padded_sentences = []
    for i in range(len(sentences)):
        sentence = sentences[i]
        if max_sequence_length <= len(sentence) :
            padded_sentences.append(sentence[:max_sequence_length])
            continue
        num_padding = max_sequence_length - len(sentence)
        new_sentence = sentence + [PAD_MARK] * num_padding
        padded_sentences.append(new_sentence)
    return padded_sentences, max_sequence_length


def build_vocab(sentences, base_vocab_path):
    """
    Builds a vocabulary mapping from word to index based on the sentences.
    Returns vocabulary mapping and inverse vocabulary mapping.
    """
    vocabulary_inv = []
    # Load base vocabulary
    if len(base_vocab_path) > 0 :
        vL = [ [w.strip()] for w in codecs.open( base_vocab_path, 'r', encoding='utf8' ).readlines() ]
        c = Counter(itertools.chain(*vL))
        vocabulary_inv = [x[0] for x in c.most_common()]
    else :
        # Build vocabulary
        word_counts = Counter(itertools.chain(*sentences))
        # Mapping from index to word
        vocabulary_inv = vocabulary_inv + [x[0] for x in word_counts.most_common()]
        if not UNK_MARK in vocabulary_inv :
            vocabulary_inv.append(UNK_MARK)
    vocabulary_inv = list(set(vocabulary_inv))
    vocabulary_inv.sort()
    # Mapping from word to index
    vocabulary = {x: i for i, x in enumerate(vocabulary_inv)}
    if not UNK_MARK in vocabulary :
        vocabulary[UNK_MARK] = vocabulary[PAD_MARK]

    return [vocabulary, vocabulary_inv]


def make_onehot(idx, size) :
    onehot = []
    for i in range(size) :
        if idx==i : onehot.append(1);
        else      : onehot.append(0);
    return onehot
# end def

def make_label_dic(labels) :
    """
    creator: myeongjin.hwang@systrangroup.com
    create date: 2016.05.22
    make 'label : one hot' dic
    """
    label_onehot = dict()
    onehot_label = dict()
    for i, label in enumerate(labels) :
        onehot =  make_onehot(i,len(labels))
        label_onehot[label] = onehot
        onehot_label[str(onehot)] = label
    return label_onehot, onehot_label
# end def

def build_onehot(labels, base_label_path):
    """
    Builds a vocabulary mapping from label to onehot based on the sentences.
    Returns vocabulary mapping and inverse vocabulary mapping.
    """
    uniq_labels = []
    # Load base vocabulary
    if len(base_label_path) > 0 :
        vL = [ [w.strip()] for w in codecs.open( base_label_path, 'r', encoding='utf8' ).readlines() ]
        c = Counter(itertools.chain(*vL))
        uniq_labels = [x[0] for x in c.most_common()]
    else :
        # Build vocabulary
        label_counts = Counter(labels)
        # Mapping from index to word
        uniq_labels = uniq_labels + [x[0] for x in label_counts.most_common()]
    uniq_labels = list(set(uniq_labels))
    uniq_labels.sort()
    label_onehot, onehot_label = make_label_dic( uniq_labels )
    return [uniq_labels, label_onehot, onehot_label]


def build_input_data(sentences, vocabulary, labels, label_onehot):
    """
    Maps sentencs and labels to vectors based on a vocabulary.
    """
    vL = []
    for sentence in sentences :
        wL = []
        for word in sentence :
            if word in vocabulary :
                wL.append( vocabulary[word] )
            else :
                wL.append( vocabulary[UNK_MARK] )
        vL.append(wL)
    x = np.array(vL)
    y = np.array([ label_onehot[label] for label in labels ])
    return [x, y]


def load_data( train_data_path, checkpoint_dir="" ):
    """
    Loads and preprocesses data.
    Returns input vectors, labels, vocabulary, and inverse vocabulary.
    """
    # Load and preprocess data
    max_sent_len_path = "" if len(checkpoint_dir)<1 else checkpoint_dir+"/max_sent_len"
    vocab_path        = "" if len(checkpoint_dir)<1 else checkpoint_dir+"/vocab"
    label_path        = "" if len(checkpoint_dir)<1 else checkpoint_dir+"/label"
    sentences, labels          = load_data_and_labels( train_data_path )
    sentences_padded, max_sequence_length = pad_sentences(sentences, max_sent_len_path)
    vocabulary, vocabulary_inv = build_vocab(sentences_padded, vocab_path)
    uniq_labels, label_onehot, onehot_label = build_onehot(labels, label_path)
    x, y = build_input_data(sentences_padded, vocabulary, labels, label_onehot)
    return [x, y, vocabulary, vocabulary_inv, onehot_label, max_sequence_length]


def load_data_and_labels( train_data_path ):
    """
    Loads data from files, splits the data into words and generates labels.
    Returns split sentences and labels.
    """
    # Load data from files
    data = list()
    labels = list()
    for line in codecs.open( train_data_path, 'r', encoding='utf8' ).readlines() :
        if 1 > len( line.strip() ) : continue;
        t = line.split(u"\t");
        if 2 != len(t) :
            print("data format error" + line)
            continue;
        data.append(t[0])
        labels.append(t[1])
    data   = [s.strip() for s in data]
    labels = [s.strip() for s in labels]
    # Split by words
    x_text = [clean_str(sent) for sent in data]
    x_text = [s.split(u" ") for s in x_text]
    return [x_text, labels]


def batch_iter(data, batch_size, num_epochs, shuffle=True):
    """
    Generates a batch iterator for a dataset.
    """
    data = np.array(data)
    data_size = len(data)
    num_batches_per_epoch = int(len(data)/batch_size) + 1
    for epoch in range(num_epochs):
        # Shuffle the data at each epoch
        if shuffle:
            shuffle_indices = np.random.permutation(np.arange(data_size))
            shuffled_data = data[shuffle_indices]
        else:
            shuffled_data = data
        for batch_num in range(num_batches_per_epoch):
            start_index = batch_num * batch_size
            end_index = min((batch_num + 1) * batch_size, data_size)
            yield shuffled_data[start_index:end_index]


#### for eval

def load_eval_data(input, checkpoint_dir=""):
    """
    Loads and preprocesses input.
    Returns input vectors, vocabulary, and inverse vocabulary.
    """
    # Load and preprocess data
    max_sent_len_path = "" if len(checkpoint_dir)<1 else checkpoint_dir+"/max_sent_len"
    vocab_path        = "" if len(checkpoint_dir)<1 else checkpoint_dir+"/vocab"
    parsed = [input.split(u" ")]
    sentences_padded, max_sequence_length = pad_sentences(parsed, max_sent_len_path)
    vocabulary, vocabulary_inv = build_vocab(sentences_padded, vocab_path)
    x = build_eval_input_data(sentences_padded, vocabulary)
    return x


def build_eval_input_data(sentences, vocabulary):
    """
    Maps sentencs and labels to vectors based on a vocabulary.
    """
    vL = []
    for sentence in sentences :
        wL = []
        for word in sentence :
            if word in vocabulary :
                wL.append( vocabulary[word] )
            else :
                wL.append( vocabulary[UNK_MARK] )
        vL.append(wL)
    return np.array(vL)
