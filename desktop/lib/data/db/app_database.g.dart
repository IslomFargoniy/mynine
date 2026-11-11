// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AnswerQueueTable extends AnswerQueue
    with TableInfo<$AnswerQueueTable, QueuedAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<int> partId = GeneratedColumn<int>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerTextMeta = const VerificationMeta(
    'answerText',
  );
  @override
  late final GeneratedColumn<String> answerText = GeneratedColumn<String>(
    'answer_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionIdsMeta = const VerificationMeta(
    'optionIds',
  );
  @override
  late final GeneratedColumn<String> optionIds = GeneratedColumn<String>(
    'option_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<String> changedAt = GeneratedColumn<String>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triesMeta = const VerificationMeta('tries');
  @override
  late final GeneratedColumn<int> tries = GeneratedColumn<int>(
    'tries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quarantinedMeta = const VerificationMeta(
    'quarantined',
  );
  @override
  late final GeneratedColumn<bool> quarantined = GeneratedColumn<bool>(
    'quarantined',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quarantined" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    attemptId,
    partId,
    questionId,
    answerText,
    optionIds,
    changedAt,
    tries,
    seq,
    quarantined,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('answer_text')) {
      context.handle(
        _answerTextMeta,
        answerText.isAcceptableOrUnknown(data['answer_text']!, _answerTextMeta),
      );
    }
    if (data.containsKey('option_ids')) {
      context.handle(
        _optionIdsMeta,
        optionIds.isAcceptableOrUnknown(data['option_ids']!, _optionIdsMeta),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('tries')) {
      context.handle(
        _triesMeta,
        tries.isAcceptableOrUnknown(data['tries']!, _triesMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('quarantined')) {
      context.handle(
        _quarantinedMeta,
        quarantined.isAcceptableOrUnknown(
          data['quarantined']!,
          _quarantinedMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      answerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_text'],
      ),
      optionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_ids'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_at'],
      )!,
      tries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tries'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      ),
      quarantined: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quarantined'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $AnswerQueueTable createAlias(String alias) {
    return $AnswerQueueTable(attachedDatabase, alias);
  }
}

class QueuedAnswer extends DataClass implements Insertable<QueuedAnswer> {
  final int id;
  final String clientUuid;
  final int attemptId;
  final int partId;
  final int questionId;
  final String? answerText;

  /// JSON array of option ids.
  final String optionIds;

  /// ISO-8601 server time of the change.
  final String changedAt;
  final int tries;

  /// Per-question change counter (API v1.1 `seq`), schema v2.
  final int? seq;

  /// The server refused this item with an unexpected error (422) even when
  /// sent alone: kept for audit, never sent again and not counted as pending,
  /// so it cannot block the rest of the queue or the final submit.
  final bool quarantined;
  final String? lastError;
  const QueuedAnswer({
    required this.id,
    required this.clientUuid,
    required this.attemptId,
    required this.partId,
    required this.questionId,
    this.answerText,
    required this.optionIds,
    required this.changedAt,
    required this.tries,
    this.seq,
    required this.quarantined,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['attempt_id'] = Variable<int>(attemptId);
    map['part_id'] = Variable<int>(partId);
    map['question_id'] = Variable<int>(questionId);
    if (!nullToAbsent || answerText != null) {
      map['answer_text'] = Variable<String>(answerText);
    }
    map['option_ids'] = Variable<String>(optionIds);
    map['changed_at'] = Variable<String>(changedAt);
    map['tries'] = Variable<int>(tries);
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    map['quarantined'] = Variable<bool>(quarantined);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  AnswerQueueCompanion toCompanion(bool nullToAbsent) {
    return AnswerQueueCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      attemptId: Value(attemptId),
      partId: Value(partId),
      questionId: Value(questionId),
      answerText: answerText == null && nullToAbsent
          ? const Value.absent()
          : Value(answerText),
      optionIds: Value(optionIds),
      changedAt: Value(changedAt),
      tries: Value(tries),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
      quarantined: Value(quarantined),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory QueuedAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedAnswer(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      partId: serializer.fromJson<int>(json['partId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      answerText: serializer.fromJson<String?>(json['answerText']),
      optionIds: serializer.fromJson<String>(json['optionIds']),
      changedAt: serializer.fromJson<String>(json['changedAt']),
      tries: serializer.fromJson<int>(json['tries']),
      seq: serializer.fromJson<int?>(json['seq']),
      quarantined: serializer.fromJson<bool>(json['quarantined']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'attemptId': serializer.toJson<int>(attemptId),
      'partId': serializer.toJson<int>(partId),
      'questionId': serializer.toJson<int>(questionId),
      'answerText': serializer.toJson<String?>(answerText),
      'optionIds': serializer.toJson<String>(optionIds),
      'changedAt': serializer.toJson<String>(changedAt),
      'tries': serializer.toJson<int>(tries),
      'seq': serializer.toJson<int?>(seq),
      'quarantined': serializer.toJson<bool>(quarantined),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  QueuedAnswer copyWith({
    int? id,
    String? clientUuid,
    int? attemptId,
    int? partId,
    int? questionId,
    Value<String?> answerText = const Value.absent(),
    String? optionIds,
    String? changedAt,
    int? tries,
    Value<int?> seq = const Value.absent(),
    bool? quarantined,
    Value<String?> lastError = const Value.absent(),
  }) => QueuedAnswer(
    id: id ?? this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    attemptId: attemptId ?? this.attemptId,
    partId: partId ?? this.partId,
    questionId: questionId ?? this.questionId,
    answerText: answerText.present ? answerText.value : this.answerText,
    optionIds: optionIds ?? this.optionIds,
    changedAt: changedAt ?? this.changedAt,
    tries: tries ?? this.tries,
    seq: seq.present ? seq.value : this.seq,
    quarantined: quarantined ?? this.quarantined,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  QueuedAnswer copyWithCompanion(AnswerQueueCompanion data) {
    return QueuedAnswer(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      partId: data.partId.present ? data.partId.value : this.partId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      answerText: data.answerText.present
          ? data.answerText.value
          : this.answerText,
      optionIds: data.optionIds.present ? data.optionIds.value : this.optionIds,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      tries: data.tries.present ? data.tries.value : this.tries,
      seq: data.seq.present ? data.seq.value : this.seq,
      quarantined: data.quarantined.present
          ? data.quarantined.value
          : this.quarantined,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedAnswer(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('questionId: $questionId, ')
          ..write('answerText: $answerText, ')
          ..write('optionIds: $optionIds, ')
          ..write('changedAt: $changedAt, ')
          ..write('tries: $tries, ')
          ..write('seq: $seq, ')
          ..write('quarantined: $quarantined, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    attemptId,
    partId,
    questionId,
    answerText,
    optionIds,
    changedAt,
    tries,
    seq,
    quarantined,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedAnswer &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.attemptId == this.attemptId &&
          other.partId == this.partId &&
          other.questionId == this.questionId &&
          other.answerText == this.answerText &&
          other.optionIds == this.optionIds &&
          other.changedAt == this.changedAt &&
          other.tries == this.tries &&
          other.seq == this.seq &&
          other.quarantined == this.quarantined &&
          other.lastError == this.lastError);
}

class AnswerQueueCompanion extends UpdateCompanion<QueuedAnswer> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<int> attemptId;
  final Value<int> partId;
  final Value<int> questionId;
  final Value<String?> answerText;
  final Value<String> optionIds;
  final Value<String> changedAt;
  final Value<int> tries;
  final Value<int?> seq;
  final Value<bool> quarantined;
  final Value<String?> lastError;
  const AnswerQueueCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.partId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.answerText = const Value.absent(),
    this.optionIds = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.tries = const Value.absent(),
    this.seq = const Value.absent(),
    this.quarantined = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  AnswerQueueCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required int attemptId,
    required int partId,
    required int questionId,
    this.answerText = const Value.absent(),
    this.optionIds = const Value.absent(),
    required String changedAt,
    this.tries = const Value.absent(),
    this.seq = const Value.absent(),
    this.quarantined = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       attemptId = Value(attemptId),
       partId = Value(partId),
       questionId = Value(questionId),
       changedAt = Value(changedAt);
  static Insertable<QueuedAnswer> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<int>? attemptId,
    Expression<int>? partId,
    Expression<int>? questionId,
    Expression<String>? answerText,
    Expression<String>? optionIds,
    Expression<String>? changedAt,
    Expression<int>? tries,
    Expression<int>? seq,
    Expression<bool>? quarantined,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (attemptId != null) 'attempt_id': attemptId,
      if (partId != null) 'part_id': partId,
      if (questionId != null) 'question_id': questionId,
      if (answerText != null) 'answer_text': answerText,
      if (optionIds != null) 'option_ids': optionIds,
      if (changedAt != null) 'changed_at': changedAt,
      if (tries != null) 'tries': tries,
      if (seq != null) 'seq': seq,
      if (quarantined != null) 'quarantined': quarantined,
      if (lastError != null) 'last_error': lastError,
    });
  }

  AnswerQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? clientUuid,
    Value<int>? attemptId,
    Value<int>? partId,
    Value<int>? questionId,
    Value<String?>? answerText,
    Value<String>? optionIds,
    Value<String>? changedAt,
    Value<int>? tries,
    Value<int?>? seq,
    Value<bool>? quarantined,
    Value<String?>? lastError,
  }) {
    return AnswerQueueCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      attemptId: attemptId ?? this.attemptId,
      partId: partId ?? this.partId,
      questionId: questionId ?? this.questionId,
      answerText: answerText ?? this.answerText,
      optionIds: optionIds ?? this.optionIds,
      changedAt: changedAt ?? this.changedAt,
      tries: tries ?? this.tries,
      seq: seq ?? this.seq,
      quarantined: quarantined ?? this.quarantined,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<int>(partId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (answerText.present) {
      map['answer_text'] = Variable<String>(answerText.value);
    }
    if (optionIds.present) {
      map['option_ids'] = Variable<String>(optionIds.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<String>(changedAt.value);
    }
    if (tries.present) {
      map['tries'] = Variable<int>(tries.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (quarantined.present) {
      map['quarantined'] = Variable<bool>(quarantined.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerQueueCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('questionId: $questionId, ')
          ..write('answerText: $answerText, ')
          ..write('optionIds: $optionIds, ')
          ..write('changedAt: $changedAt, ')
          ..write('tries: $tries, ')
          ..write('seq: $seq, ')
          ..write('quarantined: $quarantined, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $LocalAnswersTable extends LocalAnswers
    with TableInfo<$LocalAnswersTable, LocalAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<int> partId = GeneratedColumn<int>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerTextMeta = const VerificationMeta(
    'answerText',
  );
  @override
  late final GeneratedColumn<String> answerText = GeneratedColumn<String>(
    'answer_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionIdsMeta = const VerificationMeta(
    'optionIds',
  );
  @override
  late final GeneratedColumn<String> optionIds = GeneratedColumn<String>(
    'option_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<String> changedAt = GeneratedColumn<String>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    attemptId,
    questionId,
    partId,
    answerText,
    optionIds,
    changedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('answer_text')) {
      context.handle(
        _answerTextMeta,
        answerText.isAcceptableOrUnknown(data['answer_text']!, _answerTextMeta),
      );
    }
    if (data.containsKey('option_ids')) {
      context.handle(
        _optionIdsMeta,
        optionIds.isAcceptableOrUnknown(data['option_ids']!, _optionIdsMeta),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId, questionId};
  @override
  LocalAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAnswer(
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_id'],
      )!,
      answerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_text'],
      ),
      optionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_ids'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_at'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $LocalAnswersTable createAlias(String alias) {
    return $LocalAnswersTable(attachedDatabase, alias);
  }
}

class LocalAnswer extends DataClass implements Insertable<LocalAnswer> {
  final int attemptId;
  final int questionId;
  final int partId;
  final String? answerText;
  final String optionIds;
  final String changedAt;

  /// Last `seq` used for this question (schema v2).
  final int seq;
  const LocalAnswer({
    required this.attemptId,
    required this.questionId,
    required this.partId,
    this.answerText,
    required this.optionIds,
    required this.changedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<int>(attemptId);
    map['question_id'] = Variable<int>(questionId);
    map['part_id'] = Variable<int>(partId);
    if (!nullToAbsent || answerText != null) {
      map['answer_text'] = Variable<String>(answerText);
    }
    map['option_ids'] = Variable<String>(optionIds);
    map['changed_at'] = Variable<String>(changedAt);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  LocalAnswersCompanion toCompanion(bool nullToAbsent) {
    return LocalAnswersCompanion(
      attemptId: Value(attemptId),
      questionId: Value(questionId),
      partId: Value(partId),
      answerText: answerText == null && nullToAbsent
          ? const Value.absent()
          : Value(answerText),
      optionIds: Value(optionIds),
      changedAt: Value(changedAt),
      seq: Value(seq),
    );
  }

  factory LocalAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAnswer(
      attemptId: serializer.fromJson<int>(json['attemptId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      partId: serializer.fromJson<int>(json['partId']),
      answerText: serializer.fromJson<String?>(json['answerText']),
      optionIds: serializer.fromJson<String>(json['optionIds']),
      changedAt: serializer.fromJson<String>(json['changedAt']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptId': serializer.toJson<int>(attemptId),
      'questionId': serializer.toJson<int>(questionId),
      'partId': serializer.toJson<int>(partId),
      'answerText': serializer.toJson<String?>(answerText),
      'optionIds': serializer.toJson<String>(optionIds),
      'changedAt': serializer.toJson<String>(changedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  LocalAnswer copyWith({
    int? attemptId,
    int? questionId,
    int? partId,
    Value<String?> answerText = const Value.absent(),
    String? optionIds,
    String? changedAt,
    int? seq,
  }) => LocalAnswer(
    attemptId: attemptId ?? this.attemptId,
    questionId: questionId ?? this.questionId,
    partId: partId ?? this.partId,
    answerText: answerText.present ? answerText.value : this.answerText,
    optionIds: optionIds ?? this.optionIds,
    changedAt: changedAt ?? this.changedAt,
    seq: seq ?? this.seq,
  );
  LocalAnswer copyWithCompanion(LocalAnswersCompanion data) {
    return LocalAnswer(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      partId: data.partId.present ? data.partId.value : this.partId,
      answerText: data.answerText.present
          ? data.answerText.value
          : this.answerText,
      optionIds: data.optionIds.present ? data.optionIds.value : this.optionIds,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAnswer(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('partId: $partId, ')
          ..write('answerText: $answerText, ')
          ..write('optionIds: $optionIds, ')
          ..write('changedAt: $changedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attemptId,
    questionId,
    partId,
    answerText,
    optionIds,
    changedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAnswer &&
          other.attemptId == this.attemptId &&
          other.questionId == this.questionId &&
          other.partId == this.partId &&
          other.answerText == this.answerText &&
          other.optionIds == this.optionIds &&
          other.changedAt == this.changedAt &&
          other.seq == this.seq);
}

class LocalAnswersCompanion extends UpdateCompanion<LocalAnswer> {
  final Value<int> attemptId;
  final Value<int> questionId;
  final Value<int> partId;
  final Value<String?> answerText;
  final Value<String> optionIds;
  final Value<String> changedAt;
  final Value<int> seq;
  final Value<int> rowid;
  const LocalAnswersCompanion({
    this.attemptId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.partId = const Value.absent(),
    this.answerText = const Value.absent(),
    this.optionIds = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAnswersCompanion.insert({
    required int attemptId,
    required int questionId,
    required int partId,
    this.answerText = const Value.absent(),
    this.optionIds = const Value.absent(),
    required String changedAt,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attemptId = Value(attemptId),
       questionId = Value(questionId),
       partId = Value(partId),
       changedAt = Value(changedAt);
  static Insertable<LocalAnswer> custom({
    Expression<int>? attemptId,
    Expression<int>? questionId,
    Expression<int>? partId,
    Expression<String>? answerText,
    Expression<String>? optionIds,
    Expression<String>? changedAt,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (questionId != null) 'question_id': questionId,
      if (partId != null) 'part_id': partId,
      if (answerText != null) 'answer_text': answerText,
      if (optionIds != null) 'option_ids': optionIds,
      if (changedAt != null) 'changed_at': changedAt,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAnswersCompanion copyWith({
    Value<int>? attemptId,
    Value<int>? questionId,
    Value<int>? partId,
    Value<String?>? answerText,
    Value<String>? optionIds,
    Value<String>? changedAt,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return LocalAnswersCompanion(
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      partId: partId ?? this.partId,
      answerText: answerText ?? this.answerText,
      optionIds: optionIds ?? this.optionIds,
      changedAt: changedAt ?? this.changedAt,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<int>(partId.value);
    }
    if (answerText.present) {
      map['answer_text'] = Variable<String>(answerText.value);
    }
    if (optionIds.present) {
      map['option_ids'] = Variable<String>(optionIds.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<String>(changedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAnswersCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('partId: $partId, ')
          ..write('answerText: $answerText, ')
          ..write('optionIds: $optionIds, ')
          ..write('changedAt: $changedAt, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ViolationQueueTable extends ViolationQueue
    with TableInfo<$ViolationQueueTable, QueuedViolation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViolationQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<String> occurredAt = GeneratedColumn<String>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quarantinedMeta = const VerificationMeta(
    'quarantined',
  );
  @override
  late final GeneratedColumn<bool> quarantined = GeneratedColumn<bool>(
    'quarantined',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quarantined" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    attemptId,
    type,
    detail,
    occurredAt,
    quarantined,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'violation_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedViolation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('quarantined')) {
      context.handle(
        _quarantinedMeta,
        quarantined.isAcceptableOrUnknown(
          data['quarantined']!,
          _quarantinedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedViolation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedViolation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_at'],
      )!,
      quarantined: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quarantined'],
      )!,
    );
  }

  @override
  $ViolationQueueTable createAlias(String alias) {
    return $ViolationQueueTable(attachedDatabase, alias);
  }
}

class QueuedViolation extends DataClass implements Insertable<QueuedViolation> {
  final int id;
  final String clientUuid;
  final int attemptId;
  final String type;
  final String? detail;
  final String occurredAt;

  /// Refused by the server (422) even alone: kept, never resent (schema v2).
  final bool quarantined;
  const QueuedViolation({
    required this.id,
    required this.clientUuid,
    required this.attemptId,
    required this.type,
    this.detail,
    required this.occurredAt,
    required this.quarantined,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['attempt_id'] = Variable<int>(attemptId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['occurred_at'] = Variable<String>(occurredAt);
    map['quarantined'] = Variable<bool>(quarantined);
    return map;
  }

  ViolationQueueCompanion toCompanion(bool nullToAbsent) {
    return ViolationQueueCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      attemptId: Value(attemptId),
      type: Value(type),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      occurredAt: Value(occurredAt),
      quarantined: Value(quarantined),
    );
  }

  factory QueuedViolation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedViolation(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      type: serializer.fromJson<String>(json['type']),
      detail: serializer.fromJson<String?>(json['detail']),
      occurredAt: serializer.fromJson<String>(json['occurredAt']),
      quarantined: serializer.fromJson<bool>(json['quarantined']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'attemptId': serializer.toJson<int>(attemptId),
      'type': serializer.toJson<String>(type),
      'detail': serializer.toJson<String?>(detail),
      'occurredAt': serializer.toJson<String>(occurredAt),
      'quarantined': serializer.toJson<bool>(quarantined),
    };
  }

  QueuedViolation copyWith({
    int? id,
    String? clientUuid,
    int? attemptId,
    String? type,
    Value<String?> detail = const Value.absent(),
    String? occurredAt,
    bool? quarantined,
  }) => QueuedViolation(
    id: id ?? this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    attemptId: attemptId ?? this.attemptId,
    type: type ?? this.type,
    detail: detail.present ? detail.value : this.detail,
    occurredAt: occurredAt ?? this.occurredAt,
    quarantined: quarantined ?? this.quarantined,
  );
  QueuedViolation copyWithCompanion(ViolationQueueCompanion data) {
    return QueuedViolation(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      type: data.type.present ? data.type.value : this.type,
      detail: data.detail.present ? data.detail.value : this.detail,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      quarantined: data.quarantined.present
          ? data.quarantined.value
          : this.quarantined,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedViolation(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('attemptId: $attemptId, ')
          ..write('type: $type, ')
          ..write('detail: $detail, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('quarantined: $quarantined')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    attemptId,
    type,
    detail,
    occurredAt,
    quarantined,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedViolation &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.attemptId == this.attemptId &&
          other.type == this.type &&
          other.detail == this.detail &&
          other.occurredAt == this.occurredAt &&
          other.quarantined == this.quarantined);
}

class ViolationQueueCompanion extends UpdateCompanion<QueuedViolation> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<int> attemptId;
  final Value<String> type;
  final Value<String?> detail;
  final Value<String> occurredAt;
  final Value<bool> quarantined;
  const ViolationQueueCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.type = const Value.absent(),
    this.detail = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.quarantined = const Value.absent(),
  });
  ViolationQueueCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required int attemptId,
    required String type,
    this.detail = const Value.absent(),
    required String occurredAt,
    this.quarantined = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       attemptId = Value(attemptId),
       type = Value(type),
       occurredAt = Value(occurredAt);
  static Insertable<QueuedViolation> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<int>? attemptId,
    Expression<String>? type,
    Expression<String>? detail,
    Expression<String>? occurredAt,
    Expression<bool>? quarantined,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (attemptId != null) 'attempt_id': attemptId,
      if (type != null) 'type': type,
      if (detail != null) 'detail': detail,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (quarantined != null) 'quarantined': quarantined,
    });
  }

  ViolationQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? clientUuid,
    Value<int>? attemptId,
    Value<String>? type,
    Value<String?>? detail,
    Value<String>? occurredAt,
    Value<bool>? quarantined,
  }) {
    return ViolationQueueCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      attemptId: attemptId ?? this.attemptId,
      type: type ?? this.type,
      detail: detail ?? this.detail,
      occurredAt: occurredAt ?? this.occurredAt,
      quarantined: quarantined ?? this.quarantined,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(occurredAt.value);
    }
    if (quarantined.present) {
      map['quarantined'] = Variable<bool>(quarantined.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViolationQueueCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('attemptId: $attemptId, ')
          ..write('type: $type, ')
          ..write('detail: $detail, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('quarantined: $quarantined')
          ..write(')'))
        .toString();
  }
}

class $CachedPayloadsTable extends CachedPayloads
    with TableInfo<$CachedPayloadsTable, CachedPayload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPayloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPayload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CachedPayload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPayload(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedPayloadsTable createAlias(String alias) {
    return $CachedPayloadsTable(attachedDatabase, alias);
  }
}

class CachedPayload extends DataClass implements Insertable<CachedPayload> {
  final String key;
  final String json;
  final DateTime updatedAt;
  const CachedPayload({
    required this.key,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedPayloadsCompanion toCompanion(bool nullToAbsent) {
    return CachedPayloadsCompanion(
      key: Value(key),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedPayload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPayload(
      key: serializer.fromJson<String>(json['key']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedPayload copyWith({String? key, String? json, DateTime? updatedAt}) =>
      CachedPayload(
        key: key ?? this.key,
        json: json ?? this.json,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedPayload copyWithCompanion(CachedPayloadsCompanion data) {
    return CachedPayload(
      key: data.key.present ? data.key.value : this.key,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayload(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPayload &&
          other.key == this.key &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class CachedPayloadsCompanion extends UpdateCompanion<CachedPayload> {
  final Value<String> key;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedPayloadsCompanion({
    this.key = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPayloadsCompanion.insert({
    required String key,
    required String json,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       json = Value(json);
  static Insertable<CachedPayload> custom({
    Expression<String>? key,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPayloadsCompanion copyWith({
    Value<String>? key,
    Value<String>? json,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedPayloadsCompanion(
      key: key ?? this.key,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayloadsCompanion(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HighlightsTable extends Highlights
    with TableInfo<$HighlightsTable, HighlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<int> partId = GeneratedColumn<int>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startOffsetMeta = const VerificationMeta(
    'startOffset',
  );
  @override
  late final GeneratedColumn<int> startOffset = GeneratedColumn<int>(
    'start_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endOffsetMeta = const VerificationMeta(
    'endOffset',
  );
  @override
  late final GeneratedColumn<int> endOffset = GeneratedColumn<int>(
    'end_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('highlight'),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    attemptId,
    partId,
    startOffset,
    endOffset,
    kind,
    noteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<HighlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('start_offset')) {
      context.handle(
        _startOffsetMeta,
        startOffset.isAcceptableOrUnknown(
          data['start_offset']!,
          _startOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startOffsetMeta);
    }
    if (data.containsKey('end_offset')) {
      context.handle(
        _endOffsetMeta,
        endOffset.isAcceptableOrUnknown(data['end_offset']!, _endOffsetMeta),
      );
    } else if (isInserting) {
      context.missing(_endOffsetMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HighlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HighlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_id'],
      )!,
      startOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_offset'],
      )!,
      endOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_offset'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }
}

class HighlightRow extends DataClass implements Insertable<HighlightRow> {
  final int id;
  final int attemptId;
  final int partId;
  final int startOffset;
  final int endOffset;

  /// `highlight` or `note`.
  final String kind;
  final String? noteId;
  const HighlightRow({
    required this.id,
    required this.attemptId,
    required this.partId,
    required this.startOffset,
    required this.endOffset,
    required this.kind,
    this.noteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['attempt_id'] = Variable<int>(attemptId);
    map['part_id'] = Variable<int>(partId);
    map['start_offset'] = Variable<int>(startOffset);
    map['end_offset'] = Variable<int>(endOffset);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      attemptId: Value(attemptId),
      partId: Value(partId),
      startOffset: Value(startOffset),
      endOffset: Value(endOffset),
      kind: Value(kind),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
    );
  }

  factory HighlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HighlightRow(
      id: serializer.fromJson<int>(json['id']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      partId: serializer.fromJson<int>(json['partId']),
      startOffset: serializer.fromJson<int>(json['startOffset']),
      endOffset: serializer.fromJson<int>(json['endOffset']),
      kind: serializer.fromJson<String>(json['kind']),
      noteId: serializer.fromJson<String?>(json['noteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'attemptId': serializer.toJson<int>(attemptId),
      'partId': serializer.toJson<int>(partId),
      'startOffset': serializer.toJson<int>(startOffset),
      'endOffset': serializer.toJson<int>(endOffset),
      'kind': serializer.toJson<String>(kind),
      'noteId': serializer.toJson<String?>(noteId),
    };
  }

  HighlightRow copyWith({
    int? id,
    int? attemptId,
    int? partId,
    int? startOffset,
    int? endOffset,
    String? kind,
    Value<String?> noteId = const Value.absent(),
  }) => HighlightRow(
    id: id ?? this.id,
    attemptId: attemptId ?? this.attemptId,
    partId: partId ?? this.partId,
    startOffset: startOffset ?? this.startOffset,
    endOffset: endOffset ?? this.endOffset,
    kind: kind ?? this.kind,
    noteId: noteId.present ? noteId.value : this.noteId,
  );
  HighlightRow copyWithCompanion(HighlightsCompanion data) {
    return HighlightRow(
      id: data.id.present ? data.id.value : this.id,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      partId: data.partId.present ? data.partId.value : this.partId,
      startOffset: data.startOffset.present
          ? data.startOffset.value
          : this.startOffset,
      endOffset: data.endOffset.present ? data.endOffset.value : this.endOffset,
      kind: data.kind.present ? data.kind.value : this.kind,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HighlightRow(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('kind: $kind, ')
          ..write('noteId: $noteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, attemptId, partId, startOffset, endOffset, kind, noteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighlightRow &&
          other.id == this.id &&
          other.attemptId == this.attemptId &&
          other.partId == this.partId &&
          other.startOffset == this.startOffset &&
          other.endOffset == this.endOffset &&
          other.kind == this.kind &&
          other.noteId == this.noteId);
}

class HighlightsCompanion extends UpdateCompanion<HighlightRow> {
  final Value<int> id;
  final Value<int> attemptId;
  final Value<int> partId;
  final Value<int> startOffset;
  final Value<int> endOffset;
  final Value<String> kind;
  final Value<String?> noteId;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.partId = const Value.absent(),
    this.startOffset = const Value.absent(),
    this.endOffset = const Value.absent(),
    this.kind = const Value.absent(),
    this.noteId = const Value.absent(),
  });
  HighlightsCompanion.insert({
    this.id = const Value.absent(),
    required int attemptId,
    required int partId,
    required int startOffset,
    required int endOffset,
    this.kind = const Value.absent(),
    this.noteId = const Value.absent(),
  }) : attemptId = Value(attemptId),
       partId = Value(partId),
       startOffset = Value(startOffset),
       endOffset = Value(endOffset);
  static Insertable<HighlightRow> custom({
    Expression<int>? id,
    Expression<int>? attemptId,
    Expression<int>? partId,
    Expression<int>? startOffset,
    Expression<int>? endOffset,
    Expression<String>? kind,
    Expression<String>? noteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptId != null) 'attempt_id': attemptId,
      if (partId != null) 'part_id': partId,
      if (startOffset != null) 'start_offset': startOffset,
      if (endOffset != null) 'end_offset': endOffset,
      if (kind != null) 'kind': kind,
      if (noteId != null) 'note_id': noteId,
    });
  }

  HighlightsCompanion copyWith({
    Value<int>? id,
    Value<int>? attemptId,
    Value<int>? partId,
    Value<int>? startOffset,
    Value<int>? endOffset,
    Value<String>? kind,
    Value<String?>? noteId,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      partId: partId ?? this.partId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      kind: kind ?? this.kind,
      noteId: noteId ?? this.noteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<int>(partId.value);
    }
    if (startOffset.present) {
      map['start_offset'] = Variable<int>(startOffset.value);
    }
    if (endOffset.present) {
      map['end_offset'] = Variable<int>(endOffset.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('kind: $kind, ')
          ..write('noteId: $noteId')
          ..write(')'))
        .toString();
  }
}

class $CandidateNotesTable extends CandidateNotes
    with TableInfo<$CandidateNotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CandidateNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<int> partId = GeneratedColumn<int>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  @override
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
    'quote',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    attemptId,
    partId,
    quote,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'candidate_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_id'],
      )!,
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CandidateNotesTable createAlias(String alias) {
    return $CandidateNotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final int attemptId;
  final int partId;
  final String quote;
  final String note;
  final DateTime createdAt;
  const NoteRow({
    required this.id,
    required this.attemptId,
    required this.partId,
    required this.quote,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['attempt_id'] = Variable<int>(attemptId);
    map['part_id'] = Variable<int>(partId);
    map['quote'] = Variable<String>(quote);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CandidateNotesCompanion toCompanion(bool nullToAbsent) {
    return CandidateNotesCompanion(
      id: Value(id),
      attemptId: Value(attemptId),
      partId: Value(partId),
      quote: Value(quote),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      partId: serializer.fromJson<int>(json['partId']),
      quote: serializer.fromJson<String>(json['quote']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'attemptId': serializer.toJson<int>(attemptId),
      'partId': serializer.toJson<int>(partId),
      'quote': serializer.toJson<String>(quote),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NoteRow copyWith({
    String? id,
    int? attemptId,
    int? partId,
    String? quote,
    String? note,
    DateTime? createdAt,
  }) => NoteRow(
    id: id ?? this.id,
    attemptId: attemptId ?? this.attemptId,
    partId: partId ?? this.partId,
    quote: quote ?? this.quote,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteRow copyWithCompanion(CandidateNotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      partId: data.partId.present ? data.partId.value : this.partId,
      quote: data.quote.present ? data.quote.value : this.quote,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('quote: $quote, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, attemptId, partId, quote, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.attemptId == this.attemptId &&
          other.partId == this.partId &&
          other.quote == this.quote &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class CandidateNotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<int> attemptId;
  final Value<int> partId;
  final Value<String> quote;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CandidateNotesCompanion({
    this.id = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.partId = const Value.absent(),
    this.quote = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CandidateNotesCompanion.insert({
    required String id,
    required int attemptId,
    required int partId,
    required String quote,
    required String note,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       attemptId = Value(attemptId),
       partId = Value(partId),
       quote = Value(quote),
       note = Value(note);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<int>? attemptId,
    Expression<int>? partId,
    Expression<String>? quote,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptId != null) 'attempt_id': attemptId,
      if (partId != null) 'part_id': partId,
      if (quote != null) 'quote': quote,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CandidateNotesCompanion copyWith({
    Value<String>? id,
    Value<int>? attemptId,
    Value<int>? partId,
    Value<String>? quote,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CandidateNotesCompanion(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      partId: partId ?? this.partId,
      quote: quote ?? this.quote,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<int>(partId.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CandidateNotesCompanion(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('partId: $partId, ')
          ..write('quote: $quote, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamSessionsTable extends ExamSessions
    with TableInfo<$ExamSessionsTable, ExamSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _candidateNameMeta = const VerificationMeta(
    'candidateName',
  );
  @override
  late final GeneratedColumn<String> candidateName = GeneratedColumn<String>(
    'candidate_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _candidateCodeMeta = const VerificationMeta(
    'candidateCode',
  );
  @override
  late final GeneratedColumn<String> candidateCode = GeneratedColumn<String>(
    'candidate_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mockNameMeta = const VerificationMeta(
    'mockName',
  );
  @override
  late final GeneratedColumn<String> mockName = GeneratedColumn<String>(
    'mock_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submitPendingMeta = const VerificationMeta(
    'submitPending',
  );
  @override
  late final GeneratedColumn<bool> submitPending = GeneratedColumn<bool>(
    'submit_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("submit_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _authLostMeta = const VerificationMeta(
    'authLost',
  );
  @override
  late final GeneratedColumn<bool> authLost = GeneratedColumn<bool>(
    'auth_lost',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auth_lost" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attemptId,
    token,
    candidateName,
    candidateCode,
    mockName,
    expiresAt,
    submitPending,
    completed,
    closed,
    createdAt,
    authLost,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('candidate_name')) {
      context.handle(
        _candidateNameMeta,
        candidateName.isAcceptableOrUnknown(
          data['candidate_name']!,
          _candidateNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_candidateNameMeta);
    }
    if (data.containsKey('candidate_code')) {
      context.handle(
        _candidateCodeMeta,
        candidateCode.isAcceptableOrUnknown(
          data['candidate_code']!,
          _candidateCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_candidateCodeMeta);
    }
    if (data.containsKey('mock_name')) {
      context.handle(
        _mockNameMeta,
        mockName.isAcceptableOrUnknown(data['mock_name']!, _mockNameMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('submit_pending')) {
      context.handle(
        _submitPendingMeta,
        submitPending.isAcceptableOrUnknown(
          data['submit_pending']!,
          _submitPendingMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('auth_lost')) {
      context.handle(
        _authLostMeta,
        authLost.isAcceptableOrUnknown(data['auth_lost']!, _authLostMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId};
  @override
  ExamSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamSessionRow(
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      candidateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_name'],
      )!,
      candidateCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_code'],
      )!,
      mockName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mock_name'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      submitPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}submit_pending'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      authLost: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auth_lost'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $ExamSessionsTable createAlias(String alias) {
    return $ExamSessionsTable(attachedDatabase, alias);
  }
}

class ExamSessionRow extends DataClass implements Insertable<ExamSessionRow> {
  final int attemptId;
  final String token;
  final String candidateName;
  final String candidateCode;
  final String mockName;
  final DateTime? expiresAt;

  /// The candidate finished; `POST /exam/submit` still has to be delivered.
  final bool submitPending;

  /// Exam is over on this PC (Completed screen reached).
  final bool completed;

  /// Server confirmed the final submit (or the attempt is finished).
  final bool closed;
  final DateTime createdAt;

  /// The server answered 401 (`session_revoked` / `session_expired`) for this
  /// token: background sync skips the session (its queue is kept) until a
  /// new login on this PC replaces the token. Schema v2.
  final bool authLost;

  /// When [closed] was set (cleanup of old exam files). Schema v2.
  final DateTime? closedAt;
  const ExamSessionRow({
    required this.attemptId,
    required this.token,
    required this.candidateName,
    required this.candidateCode,
    required this.mockName,
    this.expiresAt,
    required this.submitPending,
    required this.completed,
    required this.closed,
    required this.createdAt,
    required this.authLost,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<int>(attemptId);
    map['token'] = Variable<String>(token);
    map['candidate_name'] = Variable<String>(candidateName);
    map['candidate_code'] = Variable<String>(candidateCode);
    map['mock_name'] = Variable<String>(mockName);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['submit_pending'] = Variable<bool>(submitPending);
    map['completed'] = Variable<bool>(completed);
    map['closed'] = Variable<bool>(closed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['auth_lost'] = Variable<bool>(authLost);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  ExamSessionsCompanion toCompanion(bool nullToAbsent) {
    return ExamSessionsCompanion(
      attemptId: Value(attemptId),
      token: Value(token),
      candidateName: Value(candidateName),
      candidateCode: Value(candidateCode),
      mockName: Value(mockName),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      submitPending: Value(submitPending),
      completed: Value(completed),
      closed: Value(closed),
      createdAt: Value(createdAt),
      authLost: Value(authLost),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory ExamSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamSessionRow(
      attemptId: serializer.fromJson<int>(json['attemptId']),
      token: serializer.fromJson<String>(json['token']),
      candidateName: serializer.fromJson<String>(json['candidateName']),
      candidateCode: serializer.fromJson<String>(json['candidateCode']),
      mockName: serializer.fromJson<String>(json['mockName']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      submitPending: serializer.fromJson<bool>(json['submitPending']),
      completed: serializer.fromJson<bool>(json['completed']),
      closed: serializer.fromJson<bool>(json['closed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      authLost: serializer.fromJson<bool>(json['authLost']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptId': serializer.toJson<int>(attemptId),
      'token': serializer.toJson<String>(token),
      'candidateName': serializer.toJson<String>(candidateName),
      'candidateCode': serializer.toJson<String>(candidateCode),
      'mockName': serializer.toJson<String>(mockName),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'submitPending': serializer.toJson<bool>(submitPending),
      'completed': serializer.toJson<bool>(completed),
      'closed': serializer.toJson<bool>(closed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'authLost': serializer.toJson<bool>(authLost),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  ExamSessionRow copyWith({
    int? attemptId,
    String? token,
    String? candidateName,
    String? candidateCode,
    String? mockName,
    Value<DateTime?> expiresAt = const Value.absent(),
    bool? submitPending,
    bool? completed,
    bool? closed,
    DateTime? createdAt,
    bool? authLost,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => ExamSessionRow(
    attemptId: attemptId ?? this.attemptId,
    token: token ?? this.token,
    candidateName: candidateName ?? this.candidateName,
    candidateCode: candidateCode ?? this.candidateCode,
    mockName: mockName ?? this.mockName,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    submitPending: submitPending ?? this.submitPending,
    completed: completed ?? this.completed,
    closed: closed ?? this.closed,
    createdAt: createdAt ?? this.createdAt,
    authLost: authLost ?? this.authLost,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  ExamSessionRow copyWithCompanion(ExamSessionsCompanion data) {
    return ExamSessionRow(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      token: data.token.present ? data.token.value : this.token,
      candidateName: data.candidateName.present
          ? data.candidateName.value
          : this.candidateName,
      candidateCode: data.candidateCode.present
          ? data.candidateCode.value
          : this.candidateCode,
      mockName: data.mockName.present ? data.mockName.value : this.mockName,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      submitPending: data.submitPending.present
          ? data.submitPending.value
          : this.submitPending,
      completed: data.completed.present ? data.completed.value : this.completed,
      closed: data.closed.present ? data.closed.value : this.closed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      authLost: data.authLost.present ? data.authLost.value : this.authLost,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamSessionRow(')
          ..write('attemptId: $attemptId, ')
          ..write('token: $token, ')
          ..write('candidateName: $candidateName, ')
          ..write('candidateCode: $candidateCode, ')
          ..write('mockName: $mockName, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('submitPending: $submitPending, ')
          ..write('completed: $completed, ')
          ..write('closed: $closed, ')
          ..write('createdAt: $createdAt, ')
          ..write('authLost: $authLost, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attemptId,
    token,
    candidateName,
    candidateCode,
    mockName,
    expiresAt,
    submitPending,
    completed,
    closed,
    createdAt,
    authLost,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamSessionRow &&
          other.attemptId == this.attemptId &&
          other.token == this.token &&
          other.candidateName == this.candidateName &&
          other.candidateCode == this.candidateCode &&
          other.mockName == this.mockName &&
          other.expiresAt == this.expiresAt &&
          other.submitPending == this.submitPending &&
          other.completed == this.completed &&
          other.closed == this.closed &&
          other.createdAt == this.createdAt &&
          other.authLost == this.authLost &&
          other.closedAt == this.closedAt);
}

class ExamSessionsCompanion extends UpdateCompanion<ExamSessionRow> {
  final Value<int> attemptId;
  final Value<String> token;
  final Value<String> candidateName;
  final Value<String> candidateCode;
  final Value<String> mockName;
  final Value<DateTime?> expiresAt;
  final Value<bool> submitPending;
  final Value<bool> completed;
  final Value<bool> closed;
  final Value<DateTime> createdAt;
  final Value<bool> authLost;
  final Value<DateTime?> closedAt;
  const ExamSessionsCompanion({
    this.attemptId = const Value.absent(),
    this.token = const Value.absent(),
    this.candidateName = const Value.absent(),
    this.candidateCode = const Value.absent(),
    this.mockName = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.submitPending = const Value.absent(),
    this.completed = const Value.absent(),
    this.closed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.authLost = const Value.absent(),
    this.closedAt = const Value.absent(),
  });
  ExamSessionsCompanion.insert({
    this.attemptId = const Value.absent(),
    required String token,
    required String candidateName,
    required String candidateCode,
    this.mockName = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.submitPending = const Value.absent(),
    this.completed = const Value.absent(),
    this.closed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.authLost = const Value.absent(),
    this.closedAt = const Value.absent(),
  }) : token = Value(token),
       candidateName = Value(candidateName),
       candidateCode = Value(candidateCode);
  static Insertable<ExamSessionRow> custom({
    Expression<int>? attemptId,
    Expression<String>? token,
    Expression<String>? candidateName,
    Expression<String>? candidateCode,
    Expression<String>? mockName,
    Expression<DateTime>? expiresAt,
    Expression<bool>? submitPending,
    Expression<bool>? completed,
    Expression<bool>? closed,
    Expression<DateTime>? createdAt,
    Expression<bool>? authLost,
    Expression<DateTime>? closedAt,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (token != null) 'token': token,
      if (candidateName != null) 'candidate_name': candidateName,
      if (candidateCode != null) 'candidate_code': candidateCode,
      if (mockName != null) 'mock_name': mockName,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (submitPending != null) 'submit_pending': submitPending,
      if (completed != null) 'completed': completed,
      if (closed != null) 'closed': closed,
      if (createdAt != null) 'created_at': createdAt,
      if (authLost != null) 'auth_lost': authLost,
      if (closedAt != null) 'closed_at': closedAt,
    });
  }

  ExamSessionsCompanion copyWith({
    Value<int>? attemptId,
    Value<String>? token,
    Value<String>? candidateName,
    Value<String>? candidateCode,
    Value<String>? mockName,
    Value<DateTime?>? expiresAt,
    Value<bool>? submitPending,
    Value<bool>? completed,
    Value<bool>? closed,
    Value<DateTime>? createdAt,
    Value<bool>? authLost,
    Value<DateTime?>? closedAt,
  }) {
    return ExamSessionsCompanion(
      attemptId: attemptId ?? this.attemptId,
      token: token ?? this.token,
      candidateName: candidateName ?? this.candidateName,
      candidateCode: candidateCode ?? this.candidateCode,
      mockName: mockName ?? this.mockName,
      expiresAt: expiresAt ?? this.expiresAt,
      submitPending: submitPending ?? this.submitPending,
      completed: completed ?? this.completed,
      closed: closed ?? this.closed,
      createdAt: createdAt ?? this.createdAt,
      authLost: authLost ?? this.authLost,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (candidateName.present) {
      map['candidate_name'] = Variable<String>(candidateName.value);
    }
    if (candidateCode.present) {
      map['candidate_code'] = Variable<String>(candidateCode.value);
    }
    if (mockName.present) {
      map['mock_name'] = Variable<String>(mockName.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (submitPending.present) {
      map['submit_pending'] = Variable<bool>(submitPending.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (authLost.present) {
      map['auth_lost'] = Variable<bool>(authLost.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamSessionsCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('token: $token, ')
          ..write('candidateName: $candidateName, ')
          ..write('candidateCode: $candidateCode, ')
          ..write('mockName: $mockName, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('submitPending: $submitPending, ')
          ..write('completed: $completed, ')
          ..write('closed: $closed, ')
          ..write('createdAt: $createdAt, ')
          ..write('authLost: $authLost, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnswerQueueTable answerQueue = $AnswerQueueTable(this);
  late final $LocalAnswersTable localAnswers = $LocalAnswersTable(this);
  late final $ViolationQueueTable violationQueue = $ViolationQueueTable(this);
  late final $CachedPayloadsTable cachedPayloads = $CachedPayloadsTable(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $CandidateNotesTable candidateNotes = $CandidateNotesTable(this);
  late final $ExamSessionsTable examSessions = $ExamSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    answerQueue,
    localAnswers,
    violationQueue,
    cachedPayloads,
    highlights,
    candidateNotes,
    examSessions,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$AnswerQueueTableCreateCompanionBuilder =
    AnswerQueueCompanion Function({
      Value<int> id,
      required String clientUuid,
      required int attemptId,
      required int partId,
      required int questionId,
      Value<String?> answerText,
      Value<String> optionIds,
      required String changedAt,
      Value<int> tries,
      Value<int?> seq,
      Value<bool> quarantined,
      Value<String?> lastError,
    });
typedef $$AnswerQueueTableUpdateCompanionBuilder =
    AnswerQueueCompanion Function({
      Value<int> id,
      Value<String> clientUuid,
      Value<int> attemptId,
      Value<int> partId,
      Value<int> questionId,
      Value<String?> answerText,
      Value<String> optionIds,
      Value<String> changedAt,
      Value<int> tries,
      Value<int?> seq,
      Value<bool> quarantined,
      Value<String?> lastError,
    });

class $$AnswerQueueTableFilterComposer
    extends Composer<_$AppDatabase, $AnswerQueueTable> {
  $$AnswerQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionIds => $composableBuilder(
    column: $table.optionIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnswerQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $AnswerQueueTable> {
  $$AnswerQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionIds => $composableBuilder(
    column: $table.optionIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnswerQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnswerQueueTable> {
  $$AnswerQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<int> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionIds =>
      $composableBuilder(column: $table.optionIds, builder: (column) => column);

  GeneratedColumn<String> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<int> get tries =>
      $composableBuilder(column: $table.tries, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$AnswerQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnswerQueueTable,
          QueuedAnswer,
          $$AnswerQueueTableFilterComposer,
          $$AnswerQueueTableOrderingComposer,
          $$AnswerQueueTableAnnotationComposer,
          $$AnswerQueueTableCreateCompanionBuilder,
          $$AnswerQueueTableUpdateCompanionBuilder,
          (
            QueuedAnswer,
            BaseReferences<_$AppDatabase, $AnswerQueueTable, QueuedAnswer>,
          ),
          QueuedAnswer,
          PrefetchHooks Function()
        > {
  $$AnswerQueueTableTableManager(_$AppDatabase db, $AnswerQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<int> attemptId = const Value.absent(),
                Value<int> partId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<String?> answerText = const Value.absent(),
                Value<String> optionIds = const Value.absent(),
                Value<String> changedAt = const Value.absent(),
                Value<int> tries = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<bool> quarantined = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => AnswerQueueCompanion(
                id: id,
                clientUuid: clientUuid,
                attemptId: attemptId,
                partId: partId,
                questionId: questionId,
                answerText: answerText,
                optionIds: optionIds,
                changedAt: changedAt,
                tries: tries,
                seq: seq,
                quarantined: quarantined,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientUuid,
                required int attemptId,
                required int partId,
                required int questionId,
                Value<String?> answerText = const Value.absent(),
                Value<String> optionIds = const Value.absent(),
                required String changedAt,
                Value<int> tries = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<bool> quarantined = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => AnswerQueueCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                attemptId: attemptId,
                partId: partId,
                questionId: questionId,
                answerText: answerText,
                optionIds: optionIds,
                changedAt: changedAt,
                tries: tries,
                seq: seq,
                quarantined: quarantined,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnswerQueueTable, QueuedAnswer>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AnswerQueueTable,
                    QueuedAnswer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnswerQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnswerQueueTable,
      QueuedAnswer,
      $$AnswerQueueTableFilterComposer,
      $$AnswerQueueTableOrderingComposer,
      $$AnswerQueueTableAnnotationComposer,
      $$AnswerQueueTableCreateCompanionBuilder,
      $$AnswerQueueTableUpdateCompanionBuilder,
      (
        QueuedAnswer,
        BaseReferences<_$AppDatabase, $AnswerQueueTable, QueuedAnswer>,
      ),
      QueuedAnswer,
      PrefetchHooks Function()
    >;
typedef $$LocalAnswersTableCreateCompanionBuilder =
    LocalAnswersCompanion Function({
      required int attemptId,
      required int questionId,
      required int partId,
      Value<String?> answerText,
      Value<String> optionIds,
      required String changedAt,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$LocalAnswersTableUpdateCompanionBuilder =
    LocalAnswersCompanion Function({
      Value<int> attemptId,
      Value<int> questionId,
      Value<int> partId,
      Value<String?> answerText,
      Value<String> optionIds,
      Value<String> changedAt,
      Value<int> seq,
      Value<int> rowid,
    });

class $$LocalAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAnswersTable> {
  $$LocalAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionIds => $composableBuilder(
    column: $table.optionIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAnswersTable> {
  $$LocalAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionIds => $composableBuilder(
    column: $table.optionIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAnswersTable> {
  $$LocalAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionIds =>
      $composableBuilder(column: $table.optionIds, builder: (column) => column);

  GeneratedColumn<String> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$LocalAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAnswersTable,
          LocalAnswer,
          $$LocalAnswersTableFilterComposer,
          $$LocalAnswersTableOrderingComposer,
          $$LocalAnswersTableAnnotationComposer,
          $$LocalAnswersTableCreateCompanionBuilder,
          $$LocalAnswersTableUpdateCompanionBuilder,
          (
            LocalAnswer,
            BaseReferences<_$AppDatabase, $LocalAnswersTable, LocalAnswer>,
          ),
          LocalAnswer,
          PrefetchHooks Function()
        > {
  $$LocalAnswersTableTableManager(_$AppDatabase db, $LocalAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> attemptId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> partId = const Value.absent(),
                Value<String?> answerText = const Value.absent(),
                Value<String> optionIds = const Value.absent(),
                Value<String> changedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAnswersCompanion(
                attemptId: attemptId,
                questionId: questionId,
                partId: partId,
                answerText: answerText,
                optionIds: optionIds,
                changedAt: changedAt,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int attemptId,
                required int questionId,
                required int partId,
                Value<String?> answerText = const Value.absent(),
                Value<String> optionIds = const Value.absent(),
                required String changedAt,
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAnswersCompanion.insert(
                attemptId: attemptId,
                questionId: questionId,
                partId: partId,
                answerText: answerText,
                optionIds: optionIds,
                changedAt: changedAt,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAnswersTable, LocalAnswer>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAnswersTable,
                    LocalAnswer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAnswersTable,
      LocalAnswer,
      $$LocalAnswersTableFilterComposer,
      $$LocalAnswersTableOrderingComposer,
      $$LocalAnswersTableAnnotationComposer,
      $$LocalAnswersTableCreateCompanionBuilder,
      $$LocalAnswersTableUpdateCompanionBuilder,
      (
        LocalAnswer,
        BaseReferences<_$AppDatabase, $LocalAnswersTable, LocalAnswer>,
      ),
      LocalAnswer,
      PrefetchHooks Function()
    >;
typedef $$ViolationQueueTableCreateCompanionBuilder =
    ViolationQueueCompanion Function({
      Value<int> id,
      required String clientUuid,
      required int attemptId,
      required String type,
      Value<String?> detail,
      required String occurredAt,
      Value<bool> quarantined,
    });
typedef $$ViolationQueueTableUpdateCompanionBuilder =
    ViolationQueueCompanion Function({
      Value<int> id,
      Value<String> clientUuid,
      Value<int> attemptId,
      Value<String> type,
      Value<String?> detail,
      Value<String> occurredAt,
      Value<bool> quarantined,
    });

class $$ViolationQueueTableFilterComposer
    extends Composer<_$AppDatabase, $ViolationQueueTable> {
  $$ViolationQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ViolationQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $ViolationQueueTable> {
  $$ViolationQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ViolationQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $ViolationQueueTable> {
  $$ViolationQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quarantined => $composableBuilder(
    column: $table.quarantined,
    builder: (column) => column,
  );
}

class $$ViolationQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ViolationQueueTable,
          QueuedViolation,
          $$ViolationQueueTableFilterComposer,
          $$ViolationQueueTableOrderingComposer,
          $$ViolationQueueTableAnnotationComposer,
          $$ViolationQueueTableCreateCompanionBuilder,
          $$ViolationQueueTableUpdateCompanionBuilder,
          (
            QueuedViolation,
            BaseReferences<
              _$AppDatabase,
              $ViolationQueueTable,
              QueuedViolation
            >,
          ),
          QueuedViolation,
          PrefetchHooks Function()
        > {
  $$ViolationQueueTableTableManager(
    _$AppDatabase db,
    $ViolationQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ViolationQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ViolationQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ViolationQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<int> attemptId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<String> occurredAt = const Value.absent(),
                Value<bool> quarantined = const Value.absent(),
              }) => ViolationQueueCompanion(
                id: id,
                clientUuid: clientUuid,
                attemptId: attemptId,
                type: type,
                detail: detail,
                occurredAt: occurredAt,
                quarantined: quarantined,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientUuid,
                required int attemptId,
                required String type,
                Value<String?> detail = const Value.absent(),
                required String occurredAt,
                Value<bool> quarantined = const Value.absent(),
              }) => ViolationQueueCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                attemptId: attemptId,
                type: type,
                detail: detail,
                occurredAt: occurredAt,
                quarantined: quarantined,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ViolationQueueTable, QueuedViolation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ViolationQueueTable,
                    QueuedViolation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ViolationQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ViolationQueueTable,
      QueuedViolation,
      $$ViolationQueueTableFilterComposer,
      $$ViolationQueueTableOrderingComposer,
      $$ViolationQueueTableAnnotationComposer,
      $$ViolationQueueTableCreateCompanionBuilder,
      $$ViolationQueueTableUpdateCompanionBuilder,
      (
        QueuedViolation,
        BaseReferences<_$AppDatabase, $ViolationQueueTable, QueuedViolation>,
      ),
      QueuedViolation,
      PrefetchHooks Function()
    >;
typedef $$CachedPayloadsTableCreateCompanionBuilder =
    CachedPayloadsCompanion Function({
      required String key,
      required String json,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CachedPayloadsTableUpdateCompanionBuilder =
    CachedPayloadsCompanion Function({
      Value<String> key,
      Value<String> json,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedPayloadsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPayloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPayloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedPayloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPayloadsTable,
          CachedPayload,
          $$CachedPayloadsTableFilterComposer,
          $$CachedPayloadsTableOrderingComposer,
          $$CachedPayloadsTableAnnotationComposer,
          $$CachedPayloadsTableCreateCompanionBuilder,
          $$CachedPayloadsTableUpdateCompanionBuilder,
          (
            CachedPayload,
            BaseReferences<_$AppDatabase, $CachedPayloadsTable, CachedPayload>,
          ),
          CachedPayload,
          PrefetchHooks Function()
        > {
  $$CachedPayloadsTableTableManager(
    _$AppDatabase db,
    $CachedPayloadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPayloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPayloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPayloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPayloadsCompanion(
                key: key,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String json,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPayloadsCompanion.insert(
                key: key,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedPayloadsTable, CachedPayload>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedPayloadsTable,
                    CachedPayload
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPayloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPayloadsTable,
      CachedPayload,
      $$CachedPayloadsTableFilterComposer,
      $$CachedPayloadsTableOrderingComposer,
      $$CachedPayloadsTableAnnotationComposer,
      $$CachedPayloadsTableCreateCompanionBuilder,
      $$CachedPayloadsTableUpdateCompanionBuilder,
      (
        CachedPayload,
        BaseReferences<_$AppDatabase, $CachedPayloadsTable, CachedPayload>,
      ),
      CachedPayload,
      PrefetchHooks Function()
    >;
typedef $$HighlightsTableCreateCompanionBuilder = HighlightsCompanion Function({
  Value<int> id,
  required int attemptId,
  required int partId,
  required int startOffset,
  required int endOffset,
  Value<String> kind,
  Value<String?> noteId,
});
typedef $$HighlightsTableUpdateCompanionBuilder = HighlightsCompanion Function({
  Value<int> id,
  Value<int> attemptId,
  Value<int> partId,
  Value<int> startOffset,
  Value<int> endOffset,
  Value<String> kind,
  Value<String?> noteId,
});

class $$HighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startOffset => $composableBuilder(
    column: $table.startOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOffset => $composableBuilder(
    column: $table.endOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startOffset => $composableBuilder(
    column: $table.startOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOffset => $composableBuilder(
    column: $table.endOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<int> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<int> get startOffset => $composableBuilder(
    column: $table.startOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endOffset =>
      $composableBuilder(column: $table.endOffset, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);
}

class $$HighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HighlightsTable,
          HighlightRow,
          $$HighlightsTableFilterComposer,
          $$HighlightsTableOrderingComposer,
          $$HighlightsTableAnnotationComposer,
          $$HighlightsTableCreateCompanionBuilder,
          $$HighlightsTableUpdateCompanionBuilder,
          (
            HighlightRow,
            BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow>,
          ),
          HighlightRow,
          PrefetchHooks Function()
        > {
  $$HighlightsTableTableManager(_$AppDatabase db, $HighlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> attemptId = const Value.absent(),
                Value<int> partId = const Value.absent(),
                Value<int> startOffset = const Value.absent(),
                Value<int> endOffset = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
              }) => HighlightsCompanion(
                id: id,
                attemptId: attemptId,
                partId: partId,
                startOffset: startOffset,
                endOffset: endOffset,
                kind: kind,
                noteId: noteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int attemptId,
                required int partId,
                required int startOffset,
                required int endOffset,
                Value<String> kind = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
              }) => HighlightsCompanion.insert(
                id: id,
                attemptId: attemptId,
                partId: partId,
                startOffset: startOffset,
                endOffset: endOffset,
                kind: kind,
                noteId: noteId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HighlightsTable, HighlightRow>(table),
                  BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HighlightsTable,
      HighlightRow,
      $$HighlightsTableFilterComposer,
      $$HighlightsTableOrderingComposer,
      $$HighlightsTableAnnotationComposer,
      $$HighlightsTableCreateCompanionBuilder,
      $$HighlightsTableUpdateCompanionBuilder,
      (
        HighlightRow,
        BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow>,
      ),
      HighlightRow,
      PrefetchHooks Function()
    >;
typedef $$CandidateNotesTableCreateCompanionBuilder =
    CandidateNotesCompanion Function({
      required String id,
      required int attemptId,
      required int partId,
      required String quote,
      required String note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CandidateNotesTableUpdateCompanionBuilder =
    CandidateNotesCompanion Function({
      Value<String> id,
      Value<int> attemptId,
      Value<int> partId,
      Value<String> quote,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CandidateNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CandidateNotesTable> {
  $$CandidateNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CandidateNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CandidateNotesTable> {
  $$CandidateNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CandidateNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CandidateNotesTable> {
  $$CandidateNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<int> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CandidateNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CandidateNotesTable,
          NoteRow,
          $$CandidateNotesTableFilterComposer,
          $$CandidateNotesTableOrderingComposer,
          $$CandidateNotesTableAnnotationComposer,
          $$CandidateNotesTableCreateCompanionBuilder,
          $$CandidateNotesTableUpdateCompanionBuilder,
          (
            NoteRow,
            BaseReferences<_$AppDatabase, $CandidateNotesTable, NoteRow>,
          ),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$CandidateNotesTableTableManager(
    _$AppDatabase db,
    $CandidateNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CandidateNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CandidateNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CandidateNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> attemptId = const Value.absent(),
                Value<int> partId = const Value.absent(),
                Value<String> quote = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CandidateNotesCompanion(
                id: id,
                attemptId: attemptId,
                partId: partId,
                quote: quote,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int attemptId,
                required int partId,
                required String quote,
                required String note,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CandidateNotesCompanion.insert(
                id: id,
                attemptId: attemptId,
                partId: partId,
                quote: quote,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CandidateNotesTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $CandidateNotesTable, NoteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CandidateNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CandidateNotesTable,
      NoteRow,
      $$CandidateNotesTableFilterComposer,
      $$CandidateNotesTableOrderingComposer,
      $$CandidateNotesTableAnnotationComposer,
      $$CandidateNotesTableCreateCompanionBuilder,
      $$CandidateNotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $CandidateNotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$ExamSessionsTableCreateCompanionBuilder =
    ExamSessionsCompanion Function({
      Value<int> attemptId,
      required String token,
      required String candidateName,
      required String candidateCode,
      Value<String> mockName,
      Value<DateTime?> expiresAt,
      Value<bool> submitPending,
      Value<bool> completed,
      Value<bool> closed,
      Value<DateTime> createdAt,
      Value<bool> authLost,
      Value<DateTime?> closedAt,
    });
typedef $$ExamSessionsTableUpdateCompanionBuilder =
    ExamSessionsCompanion Function({
      Value<int> attemptId,
      Value<String> token,
      Value<String> candidateName,
      Value<String> candidateCode,
      Value<String> mockName,
      Value<DateTime?> expiresAt,
      Value<bool> submitPending,
      Value<bool> completed,
      Value<bool> closed,
      Value<DateTime> createdAt,
      Value<bool> authLost,
      Value<DateTime?> closedAt,
    });

class $$ExamSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidateCode => $composableBuilder(
    column: $table.candidateCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mockName => $composableBuilder(
    column: $table.mockName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get authLost => $composableBuilder(
    column: $table.authLost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExamSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidateCode => $composableBuilder(
    column: $table.candidateCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mockName => $composableBuilder(
    column: $table.mockName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get authLost => $composableBuilder(
    column: $table.authLost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get candidateCode => $composableBuilder(
    column: $table.candidateCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mockName =>
      $composableBuilder(column: $table.mockName, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get authLost =>
      $composableBuilder(column: $table.authLost, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $$ExamSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamSessionsTable,
          ExamSessionRow,
          $$ExamSessionsTableFilterComposer,
          $$ExamSessionsTableOrderingComposer,
          $$ExamSessionsTableAnnotationComposer,
          $$ExamSessionsTableCreateCompanionBuilder,
          $$ExamSessionsTableUpdateCompanionBuilder,
          (
            ExamSessionRow,
            BaseReferences<_$AppDatabase, $ExamSessionsTable, ExamSessionRow>,
          ),
          ExamSessionRow,
          PrefetchHooks Function()
        > {
  $$ExamSessionsTableTableManager(_$AppDatabase db, $ExamSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> attemptId = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<String> candidateName = const Value.absent(),
                Value<String> candidateCode = const Value.absent(),
                Value<String> mockName = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> submitPending = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> authLost = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => ExamSessionsCompanion(
                attemptId: attemptId,
                token: token,
                candidateName: candidateName,
                candidateCode: candidateCode,
                mockName: mockName,
                expiresAt: expiresAt,
                submitPending: submitPending,
                completed: completed,
                closed: closed,
                createdAt: createdAt,
                authLost: authLost,
                closedAt: closedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> attemptId = const Value.absent(),
                required String token,
                required String candidateName,
                required String candidateCode,
                Value<String> mockName = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> submitPending = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> authLost = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => ExamSessionsCompanion.insert(
                attemptId: attemptId,
                token: token,
                candidateName: candidateName,
                candidateCode: candidateCode,
                mockName: mockName,
                expiresAt: expiresAt,
                submitPending: submitPending,
                completed: completed,
                closed: closed,
                createdAt: createdAt,
                authLost: authLost,
                closedAt: closedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExamSessionsTable, ExamSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExamSessionsTable,
                    ExamSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExamSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamSessionsTable,
      ExamSessionRow,
      $$ExamSessionsTableFilterComposer,
      $$ExamSessionsTableOrderingComposer,
      $$ExamSessionsTableAnnotationComposer,
      $$ExamSessionsTableCreateCompanionBuilder,
      $$ExamSessionsTableUpdateCompanionBuilder,
      (
        ExamSessionRow,
        BaseReferences<_$AppDatabase, $ExamSessionsTable, ExamSessionRow>,
      ),
      ExamSessionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnswerQueueTableTableManager get answerQueue =>
      $$AnswerQueueTableTableManager(_db, _db.answerQueue);
  $$LocalAnswersTableTableManager get localAnswers =>
      $$LocalAnswersTableTableManager(_db, _db.localAnswers);
  $$ViolationQueueTableTableManager get violationQueue =>
      $$ViolationQueueTableTableManager(_db, _db.violationQueue);
  $$CachedPayloadsTableTableManager get cachedPayloads =>
      $$CachedPayloadsTableTableManager(_db, _db.cachedPayloads);
  $$HighlightsTableTableManager get highlights =>
      $$HighlightsTableTableManager(_db, _db.highlights);
  $$CandidateNotesTableTableManager get candidateNotes =>
      $$CandidateNotesTableTableManager(_db, _db.candidateNotes);
  $$ExamSessionsTableTableManager get examSessions =>
      $$ExamSessionsTableTableManager(_db, _db.examSessions);
}
